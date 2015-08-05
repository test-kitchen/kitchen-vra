require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.profiles.define 'gem' do
    command_name 'Specs'
  end
  SimpleCov.start 'gem'
end
