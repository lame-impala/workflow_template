# Workflow template
The purpose of this library is to provide a framework 
for defining and executing complex workflows as a series of actions, 
with robust error handling, validation, and state management. 
By extending or inheriting from the library's classes and modules, 
developers can create flexible and maintainable workflows that seamlessly 
integrate with existing projects, supporting custom validation adapters 
and state adapters to bridge different control mechanisms.

## Declaring a template
A template is a module or class extending `WorkflowTemplate::Workflow::ModuleMethods` 
that declares a sequence of named actions. Simple declaration would look like this:

```ruby rspec simple_declaration
module SimpleWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods
  
  apply(:add_thirteen)
  and_then(:multiply_by_three)
  and_then(:divide_by_seven)
   
  freeze
end
```

The two methods to declare an action – `apply` and `and_then` – are synonyms and 
can be used interchangeably. However, the intention is to use them as shown: 
declaration starts with `apply` followed by a series of `and_then`.

The class or module must be frozen at the end. An unfrozen 
workflow template is considered to be in construction – actions can
be added, removed or rearranged. Only the call to `freeze` fixes everything 
in place. Note that `freeze` raises error when the declaration 
is incomplete or ambiguous.

### Wrapper actions
Some actions need to wrap around a portion of the template 
or the whole of it. A typical example would be a step adding logging 
or one that opens a database transaction. There are two ways 
to declare such actions. The first is to simply open a block
and declare nested steps inside:

```ruby rspec nested_actions_declaration
module NestedActionsWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods

  apply(:log) do 
    and_then(:validate_model)
    and_then(:transaction) do 
      and_then(:update_model)
      and_then(:update_dependencies)
    end
  end

  freeze
end
```

Sometimes it is useful to declare a wrapper action that is engaged 
only under certain conditions. For example logging step may 
be applicable only in environments other than `production`. 
Alternative syntax can be used to achieve this, though it is limited 
to actions that wrap around the entire template, not just a part of it.

```ruby rspec wrapper_actions_declaration
module WrapperActionsWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods

  wrap_template(:log) unless Rails.env.production?
   
  apply(:validate_model)
  and_then(:transaction) do 
    and_then(:update_model)
    and_then(:update_dependencies)
  end
   
  freeze
end
```

### Defaults
For both simple and wrapper actions alike, there's an option 
to provide default for certain action arguments. This can be useful 
when an additional service object is used inside an action but 
we want to allow injecting a mock object in tests or 
for debugging purposes. The following declaration shows an action 
that receives a default logger:

```ruby rspec action_with_default
apply(:log_inputs, defaults: { logger: LOGGER })
```

## Defining an implementation
To run a workflow, a receiver object must be supplied 
that implements a method for every template action.

The implementation object should be stateless although this isn't enforced.
Usually the entire state is maintained by the template 
processor that passes it into each individual action in turn.

It is expected that each action will return a hash with symbolic keys.
There are two reserved keys with special meanings.
If the hash contains `:error` key with a truthy value, the action is considered
unsuccessful and processing will finish at this point. Another special
key is `:halted` which also will stop processing, but in this case the outcome
will be reported as success.

What will happen to the object returned from an action depends on the
`default_state_transition_strategy` setting, which takes two values, `:merge` and
`:update`, defaulting to `:merge`.

- With **merge** strategy the intermediate state and the fresh result
are combined together and the whole is passed to the next action.
This means the action can return just the new or updated keys
and ignore parameters that are not meaningful in the given context.
If the action is a pure effect and has nothing to return, `nil`
is also an acceptable return value. This means individual actions
can be designed independently from each other, not really having
to care about the precise interface of the next one.
- When the **update** strategy is specified, only the exact result returned
from an action is passed into the next action, and the previous
state is discarded. The advantage of this approach may be that it 
provides better visibility of the parameters used 
throughout the template and possibly leads to more thoughtfully 
designed method interfaces.

### Implementing simple actions
A simple action is a method that accepts a set of keyword arguments 
and returns a hash with symbolic keys. The following example
demonstrates an implementation using module functions:

```ruby rspec simple_implementation
module SimpleImplementation
  def self.add_thirteen(input:)
    { intermediate: input + 13 }
  end

  def self.multiply_by_three(intermediate:, **)
    { intermediate: intermediate * 3 }
  end

  def self.divide_by_seven(intermediate:, **)
    { result: intermediate / 7 }
  end
end
```

### Implementing wrapper actions
A wrapper action is a bit more involved. There's a block passed 
to the action alongside the usual keyword arguments. 
The action will in most cases call the block exactly once and return 
whatever the block returns. A typical pattern would look like this:

```ruby rspec logging_wrapper_action
def self.log(**input, &block)
  Logger.log('Entering workflow')
  result = block.call(**input)
  Logger.log('Exiting workflow')
  result
end
```

The block can be called safely multiple times, eg. when implementing 
retry logic for actions that might fail. The workflow's internal 
state is immutable and is recreated with each call. Therefore 
only the parameters provided in each attempt will be 
visible within the block.

## Executing a workflow
With both the template and the implementation in place, we can call 
the `perform` method on the template with a hash containing 
all input data and an implementation object as arguments. 
All actions will be invoked as method calls on the
implementation object in order of declaration.

Merge strategy being the default, the workflow declared earlier 
will yield an outcome containing all keys that were ever returned 
from any action within the workflow along with the keys sent in as the input:

```ruby rspec merge_strategy_execution
outcome = SimpleWorkflow.perform({ input: 1 }, SimpleImplementation)
expect(outcome.data).to eq({ input: 1, intermediate: 42, result: 6 })
```

To change this behavior, the `default_state_transition_strategy` 
method is available in the template body. Instead of setting 
an overall default strategy, the strategy can be set 
for individual steps. It is also possible to combine 
both approaches like so:

```ruby rspec mixed_strategy_declaration
module MixedStrategyWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods

  default_state_transition_strategy :merge

  apply(:add_thirteen)
  and_then(:multiply_by_three)
  and_then(:divide_by_seven, state: :update)
  
  freeze
end
```

When we run the workflow modified this way, we can see that the outcome 
now contains only the return value of the very last action.

```ruby rspec mixed_strategy_execution
outcome = MixedStrategyWorkflow.perform({ input: 1 }, SimpleImplementation)
expect(outcome.data).to eq({ result: 6 })
```

To normalize output after all actions have been performed, the recommended 
approach is to specify the shape of the return value using `normalize_output` method. 
This will ensure output is normalized even if the workflow template exited early 
(using the `halted` key) and also that all desired keys will always be present 
in the output, with extra keys omitted and missing keys set to `nil`. 
Note that `error` key gets special treatment and will never be omitted 
from the output if it has a truthy value.

```ruby rspec normalize_output_declaration
module NormalizeOutputWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods
   
  apply(:add_thirteen)
  and_then(:multiply_by_three)
  and_then(:divide_by_seven)
   
  normalize_output :result, :extra
  freeze
end
```

We can run the workflow now to verify that the output is normalized:

```ruby rspec normalize_output_execution
outcome = NormalizeOutputWorkflow.perform({ input: 1 }, SimpleImplementation)
expect(outcome.data).to eq({ result: 6, extra: nil })
```

### Implicit implementation object
So far we have shown templates declared on a module extending 
`WorkflowTemplate::Workflow::ModuleMethods`. There is also the `Workflow` class,
that can be inherited from. The advantage over the prior approach is that
we get an implicit implementation object, which is an instance
of the given workflow class, so any instance method implemented by the class
becomes an action implementation. The declaration will look like this:

```ruby rspec impl_object_declaration
class ImplObjectWorkflow < WorkflowTemplate::Workflow
  apply(:add_thirteen)
  and_then(:multiply_by_three)
  and_then(:divide_by_seven)
   
  def add_thirteen(input:)
    { intermediate: input + 13 }
  end
   
  def multiply_by_three(intermediate:, **)
   { intermediate: intermediate * 3 }
  end
   
  def divide_by_seven(intermediate:, **)
    { result: intermediate / 7 }
  end
   
  freeze
end
```

Such a workflow can be invoked both ways: calling the class method, 
providing custom implementation, or calling the `perform` instance
method on the implementation object.

```ruby rspec impl_object_execution
outcome = ImplObjectWorkflow.impl.perform({ input: 1 })
expect(outcome.data).to eq({ input: 1, intermediate: 42, result: 6 })
```

### Execution errors
Whenever an error is raised inside an action, it is rescued and stored inside
the state, along with other values that may already be there. The process is then
aborted and an outcome with all the accumulated data is returned. 
The workflow will also enter the error state when any truthy value is returned 
directly from the action under the `:error` key. This is actually the preferred 
way of reporting an error given that instantiation of an error object is 
a relatively costly operation.

The workflow rescues most errors that occur inside the `perform` method but not all. 
There is one specific class of errors – `WorkflowTemplate::Fatal` – that is never rescued
and falls through the stack to the call site. This happens when some action declared
in the template is not defined on the implementation object, or the action returns an
unexpected type (anything else than a hash with symbolic keys or `nil`). 
Also `ArgumentError` is re-raised when it occurs immediately during the invocation 
of an action, but it receives no special treatment when raised deeper in the stack.

### Halting the process
There may be a good reason to halt the process with a successful outcome,
for example to prevent a costly operation that makes no sense
for the given case. This can be done at any stage by returning a truthy value 
under the `:halted` key. A symbol or string can be used
to identify the reason why the process was halted to facilitate special handling
for such case. The outcome of the workflow will be a success
unless some error is returned along with it.

## Handling the outcome
The outcome object holds the data resulting from the workflow
execution. It has a `status` property set to `:ok` or `:error`
to inform whether execution was successful. An intuitive approach 
to outcome handling may be to first check the state of the outcome 
and then access the data hash directly:

```ruby rspec basic_handling
if outcome.status == :ok
  use_result(outcome.data[:result])
else
  handle_error(outcome.data[:error])    
end
```

There are more convenient ways to do this. We can call either 
of the `unwrap`, `slice` or `fetch` methods – these will succeed
with successful outcome and raise an error otherwise.
- `unwrap` just returns the final state hash
- `slice` and `fetch` both take parameters to specify what
key or keys client code is interested in. While `fetch` returns 
one single value, `slice` will return a tuple containing 
all values under specified keys. Those that are missing 
from the data will be returned as `nil`.

```ruby rspec unwrapping_outcome
@foo = outcome.fetch(:foo)
@bar, @bax = outcome.slice(:bar, :bax)
@result_hash = outcome.unwrap
```

A more sophisticated way to deal with the outcome is to use a handler block:

```ruby rspec simple_handler_block
outcome.handle do 
  ok do |result:, **|
    use_result(result)
  end
  otherwise_unwrap
end
```

Once the handler block is opened, it must account for 
both `ok` and `error` outcome. When a handler for one of 
the two possible outcomes is missing, the handler block 
always raises an error no matter what the actual outcome would be.
The `otherwise_unwrap` statement shown above can be used
instead of `ok` or `error` handler as a shortcut. It is activated
with an outcome that is not handled explicitly and its effect
is the same as a direct call to the `unwrap` method. 
In presence of an error it will re-raise, otherwise 
the final state will be returned.

Whatever value is returned from an individual handler becomes
the return value of the entire handler block so it can be 
used in the enclosing scope. The handlers are actually bound 
to the enclosing scope themselves, so whatever variables and methods 
are visible out there, they can be referred to
or assigned to inside the handler.

It is possible to handle specific errors in a separate block, 
matching on their type or value. All possible states need 
to be covered so a catch-all `error` block or `otherwise_unwrap` 
statement must be present.

```ruby rspec complete_handler_block
outcome.handle do 
  ok do |result:, **|
    use_result(result)
  end
  error(:unauthorized) do |**|
    unauthorized!
  end
  error(ActiveRecord::RecordNotFound) do |**|
    not_found!
  end
  error do |error:, **|
    handle_error(error)
  end
end
```

## Validation
The library allows for declaring validations
that are run at certain points in the workflow. 
Whenever a validation doesn't pass it stores 
an error into the state hash, turning 
a successful result into failure.

Validation is declared using `declare_validations`
module method that accepts `name` as the first positional
parameter and the `using` keyword specifying validation adapter to be used.

This is followed by an invocation of the `validate` method 
that takes optional `key` as the first parameter, along with 
some keyword arguments or a block depending on the adapter in use. 
The `key` parameter specifies which key from the state hash 
will be passed to the validator. When it is not provided, 
the whole state hash will be passed in. Naturally in that 
case the `name` parameter is required.

Once validation is declared, it can be hooked on three
different points:
- Entry point into the workflow using `validate_input`.
- Exit point from the workflow using `validate_output`.
Both methods expect symbol or an array of symbols as parameters
referring to the names of validations declared on the workflow.
- After any of the declared actions using `validate` keyword
argument. It takes a single validation name or an array of
them.

```ruby rspec validation_declaration
module ValidatingWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods

  declare_validation(using: :active_model).validate(:model)

  apply(:authorize)
  and_then(:populate, validate: :model)
  and_then(:save)
  
  freeze
end
```

Failed validation adds an `:error` key to the state with a value of a specific class
– `WorkflowTemplate::Validation::Result::Failure`. This makes it possible
to handle validation errors in a separate block, an approach encouraged 
by the library which even adds the `invalid` handler as syntax sugar:

```ruby rspec invalid_handler_block
outcome.handle do 
  ok do |result:, **|
    use_result(result)
  end
  invalid do |error:, **|
    handle_invalid(error)
  end
  error do |error:, **|
    handle_error(error)
  end
end
```

Currently there are three ready-to-use validation adapters:
- `:generic` accepts a block that returns `true` when validation passes
and `false` followed by optional detail when validation fails.
- `:active_model` works with anything that includes `ActiveModel::Validations`
or implements similar behavior.
- `:dry_validation` validates the input against `Dry::Validation::Contract`.

The following code declares validations using all available adapters.
Multiple validations may be declared for each hook or action. They will run
in order of declaration and the process will stop with the first failed validation. 
This means that even if there are multiple validations declared for
a hook or action, only a single validation error is ever present in the outcome.

```ruby rspec multiple_validation_declaration
require 'workflow_template/adapters/validation/dry_validation'
require 'workflow_template/adapters/validation/active_model'

class MultipleValidationWorkflow
  extend WorkflowTemplate::Workflow::ModuleMethods

  declare_validation(:contract, using: :dry_validation).validate(contract: Contract)
  declare_validation(:authorization, using: :generic).validate(:user) do |user|
    user.can?(:do_stuff) ? true : [false, :unauthorized]
  end
  declare_validation(using: :active_model).validate(:model)

  validate_input :contract
  validate_input [:authorization]

  apply(:populate, validate: :model)
  and_then(:save)

  freeze
end
```

The library is open to extension and allows for custom 
validation adapters to be added. Please refer 
to existing adapters to see how this is done.

## Redefining the flow
When template is declared as a class instead of a module, 
it can be inherited from and modified in a subclass. 
The subclasses will mostly just override implementation methods, 
but sometimes there's a need to add, remove or
replace declared actions. This can be done using following methods:

```ruby rspec simple_action_redeclaration
class SimpleSuperclass < Workflow 
  apply :first 
  and_then :third

  freeze
end

class SimpleSubclass < SimpleSuperclass
  replace_action(:first).apply(:new_first)
  prepend_action(before: :third).apply(:second)
  append_action(after: :third).apply(:fourth)

  freeze
end
```

Even nested actions can be rearranged using `inside_action` with a block:

```ruby rspec wrapper_action_redeclaration
class NestingSuperclass < WorkflowTemplate::Workflow
  apply(:wrapper) do
    and_then(:nested)
  end

  freeze
end

class NestingSubclass < NestingSuperclass
  inside_action(:wrapper) do
    prepend_action(before: :nested).apply(:before_nested)
    append_action(after: :nested).apply(:after_nested)
  end

  freeze
end
```

Note that during development, the `describe` class method
can be used to check the result of these modifications.

```ruby rspec wrapper_action_description
expect(NestingSubclass.describe).to eq(<<~DESC)
  state: merge

  wrapper
    before_nested
    nested
    after_nested
DESC
```

## State adapter
The control flow in template processing is straightforward:
whenever the result hash contains a truthy value 
under `:error` key, the action is considered failed. 
When integrating workflow templates into 
an existing project that uses some other control mechanism,
such as a result monad, the presence of two incompatible
conventions may be perceived as an obstacle. To bridge this gap,
the library provides an extension point: the state adapter. 
It exposes a couple of methods to be overridden in order to translate 
between workflow template built-in internal state representation 
(a hash) and whatever other structure the client code may be using. 
As an example implementation, the library ships with the 
`Dry::Monads::Result` adapter. To switch between adapters, 
use `state_adapter` method: 

```ruby rspec dry_monads_workflow
require 'workflow_template/adapters/state/dry_monads'

class DryMonadsWorkflow < WorkflowTemplate::Workflow
  include Dry::Monads[:result]
  
  state_adapter :dry_monads
  
  apply(:increment)
  
  def increment(input:, **)
    Success(output: input + 1)  
  end
  
  freeze
end
```

The outcome of such workflow is the same as with the default state adapter,
with all handling methods available. Nevertheless, it is also possible
to convert the outcome into the custom result object and use its
own methods to access and process the final state:

```ruby rspec dry_monads_outcome
outcome = DryMonadsWorkflow.impl.perform({ input: 1 })
expect(outcome.to_result.value!).to eq({ input: 1, output: 2 })
```

The `to_result` method can transform result between different 
state adapters. This way, a workflow that uses `:default` adapter internally
can wrap the result hash into `Dry::Monads::Result` as shown here:

```ruby rspec final_state_transformation
require 'workflow_template/adapters/state/dry_monads'

outcome = ImplObjectWorkflow.impl.perform({ input: 1 })
expect(outcome.to_result(:dry_monads).value!).to eq({ input: 1, intermediate: 42, result: 6 })
```

## License
This library is published under MIT license
