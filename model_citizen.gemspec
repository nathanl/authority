# -*- encoding: utf-8 -*-
require File.expand_path('../lib/model_citizen/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nathan Long"]
  gem.email         = ["nathan.long@tma1.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.add_dependency "rails", ">= 3.0.0"
  gem.add_development_dependency "bundler", ">= 1.0.0"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "model_citizen"
  gem.require_paths = ["lib"]
  gem.version       = ModelCitizen::VERSION
end
