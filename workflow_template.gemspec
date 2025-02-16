# frozen_string_literal: true

require_relative 'lib/workflow_template'

Gem::Specification.new do |s|
  s.name        = 'workflow_template'
  s.version     = WorkflowTemplate::VERSION
  s.licenses    = ['MIT']
  s.homepage    = 'https://github.com/lame-impala/workflow_template'
  s.summary     = 'Compose actions into workflows'
  s.description = <<~DESC
    Workflow templates allow to arrange simple actions together
    into workflows. Validity of intermediate result is checked
    between steps. Wrapper blocks for whole workflows may be defined.
    Different outcomes are handled in exit blocks.
  DESC
  s.authors     = ['Tomas Milsimer']
  s.email       = 'tomas.milsimer@protonmail.com'
  s.files       = Dir.glob(File.join('lib', '**', '*.rb'))
  s.required_ruby_version = '>= 2.7.3'

  s.metadata['rubygems_mfa_required'] = 'true'
end
