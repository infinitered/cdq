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
  gem.version       = CDQ::VERSION
end
