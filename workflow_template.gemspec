# frozen_string_literal: true

require_relative 'lib/workflow_template'

Gem::Specification.new do |s|
  s.name        = 'workflow_template'
  s.version     = WorkflowTemplate::VERSION
  s.licenses    = ['MIT']
  s.homepage    = 'https://github.com/lame-impala/workflow_template'
  s.metadata['homepage_uri'] = s.homepage
  s.summary     = 'Compose actions into workflows'
  s.description = <<~DESC
    The purpose of this library is to provide a framework
    for defining and executing complex workflows as a series of actions,
    with robust error handling, validation, and state management.
    By extending or inheriting from the library's classes and modules,
    developers can create flexible and maintainable workflows that seamlessly
    integrate with existing projects, supporting custom validation adapters
    and state adapters to bridge different control mechanisms.
  DESC
  s.authors     = ['Tomas Milsimer']
  s.email       = 'tomas.milsimer@protonmail.com'
  s.files       = Dir.glob(File.join('lib', '**', '*.rb'))
  s.required_ruby_version = '>= 2.7.3'
end
