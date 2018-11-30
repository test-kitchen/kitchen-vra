# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/driver/vra_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-vra'
  spec.version       = Kitchen::Driver::VRA_VERSION
  spec.authors       = ['Chef Partner Engineering']
  spec.email         = ['partnereng@chef.io']
  spec.summary       = 'A Test Kitchen driver for VMware vRealize Automation (vRA)'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/chef-partners/kitchen-vra'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'test-kitchen'
  spec.add_dependency 'vmware-vra', '~> 2'
  spec.add_dependency 'highline'
  spec.add_dependency 'rack', '~> 1.6' unless RUBY_VERSION.index('2.0.').nil?
  spec.add_dependency 'ffi-yajl', '~> 2.2.3' unless RUBY_VERSION.index('2.0.').nil?
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency 'rake',      '~> 10.0'
  spec.add_development_dependency 'rspec',     '~> 3.2'
  spec.add_development_dependency 'simplecov', '~> 0.10'
  spec.add_development_dependency 'webmock',   '~> 1.21'
  spec.add_development_dependency 'rubocop',   '~> 0.49.0'
end
