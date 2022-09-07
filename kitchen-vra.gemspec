# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kitchen/driver/vra_version"

Gem::Specification.new do |spec|
  spec.name          = "kitchen-vra"
  spec.version       = Kitchen::Driver::VRA_VERSION
  spec.authors       = ["Chef Commmunity Tools Team"]
  spec.email         = ["oss@chef.io"]
  spec.summary       = "A Test Kitchen driver for VMware vRealize Automation (vRA)"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/test-kitchen/kitchen-vra"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "test-kitchen"
  spec.add_dependency "vmware-vra", ">= 3.1.0" # 3.0 required for vRA 8.x
  spec.add_dependency "highline"
  spec.add_dependency "rack", ">= 1.6", "< 4.0"
  spec.add_dependency "ffi-yajl", ">= 2.2.3", "< 2.5.0"
  spec.add_development_dependency "rake",      "~> 13.0"
  spec.add_development_dependency "rspec",     "~> 3.2"
  spec.add_development_dependency "simplecov", "~> 0.10"
  spec.add_development_dependency "webmock",   "~> 3.14"
  spec.add_development_dependency "chefstyle", "~> 2.2.1"
end
