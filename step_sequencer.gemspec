require_relative 'lib/step_sequencer/version'

Gem::Specification.new do |gem|
  gem.name          = 'step-sequencer'
  gem.version       = StepSequencer::VERSION
  gem.authors       = ['Joseph Martin Giralt']
  gem.email         = ['joe.m.giralt+step-sequencer@gmail.com']
  gem.description   = <<~DESC
    StepSequencer is a Ruby gem providing a lightweight,#{' '}
    intuitive DSL for defining and orchestrating a sequence
     of operations, also known as a workflow. Inspired by#{' '}
     the functionality of musical sequencers, StepSequencer#{' '}
     allows developers to chain together a series of steps#{' '}
     that are executed in order, with the capability to halt
      the sequence based on custom conditions. This gem is#{' '}
      particularly useful for scenarios where a set of tasks#{' '}
      must be performed in a specific sequence, and where#{' '}
      each task might depend on the outcome of the previous#{' '}
      one.
  DESC
  gem.summary       = 'A gem for defining and executing ordered workflows with ease. Chain tasks, handle conditional halts, and streamline process flows in your applications'
  gem.licenses      = ['MIT']
  gem.homepage      = 'https://github.com/joegiralt/step-sequencer'

  gem.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.extra_rdoc_files = [
    'README.adoc'
  ]

  gem.required_ruby_version = '>= 2.6.6'
  # gem.add_development_dependency 'rdoc',          '~> 6.1'
  # gem.add_development_dependency 'bundler',       '~> 2.0'
end
