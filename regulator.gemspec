# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'regulator/version'

Gem::Specification.new do |spec|
  spec.name          = "regulator"
  spec.version       = Regulator::VERSION
  spec.authors       = ["Cory O'Daniel"]
  spec.email         = ["gems@coryodaniel.com"]

  spec.summary       = %q{Minimal controller-based authorization for Rails}
  spec.description   = %q{Minimal controller-based authorization for Rails}
  spec.homepage      = "https://github.com/coryodaniel/regulator"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3.0.0"
  spec.add_development_dependency "activemodel", ">= 3.0.0"
  spec.add_development_dependency "actionpack", ">= 3.0.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", ">=2.0.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "yard"
end
