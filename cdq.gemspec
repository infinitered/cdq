# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cdq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["infinitered", "kemiller"]
  gem.email         = ["ken@infinitered.com"]
  gem.description   = "Core Data Query for RubyMotion"
  gem.summary       = "Core Data Query for RubyMotion"
  gem.homepage      = "http://github.com/infinitered/cdq"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "cdq"
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'ruby-xcdm', '~> 0.0', '>= 0.0.5'
  gem.add_runtime_dependency 'motion-yaml'
  gem.version       = CDQ::VERSION
end
