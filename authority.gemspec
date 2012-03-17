# -*- encoding: utf-8 -*-
require File.expand_path('../lib/authority/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nathan Long", "Adam Hunter"]
  gem.email         = ["nathanmlong@gmail.com", "adamhunter@me.com"]
  gem.description   = %q{Gem for managing authorization on model actions in Rails.}
  gem.summary       = %q{Authority gives you a clean and easy way to say, in your Rails app, **who** is allowed to do **what** with your models, with minimal clutter.}
  gem.homepage      = "https://github.com/nathanl/authority"

  gem.add_dependency "rails", ">= 3.0.0"
  gem.add_development_dependency "bundler", ">= 1.0.0"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "authority"
  gem.require_paths = ["lib"]
  gem.version       = Authority::VERSION
end
