# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cdq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["infinitered", "kemiller"]
  gem.email         = ["ken@infinitered.com"]
  gem.description   = "Core Data Query for RubyMotion"
  gem.summary       = "A streamlined library for working with Core Data outside XCode"
  gem.homepage      = "http://infinitered.com/cdq"
  gem.license       = 'MIT'

  files = []
  files << 'README.md'
  files << 'LICENSE'
  files.concat(Dir.glob('lib/**/*.rb'))
  files.concat(Dir.glob('motion/**/*.rb'))
  files.concat(Dir.glob('templates/**/*.rb'))
  files.concat(Dir.glob('vendor/**/*.{rb,m,h}'))
  gem.files = files
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "cdq"
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'ruby-xcdm', '~> 0.0', '>= 0.0.7'
  gem.add_runtime_dependency 'motion-yaml'
  gem.executables << 'cdq'

  gem.version       = CDQ::VERSION
end
