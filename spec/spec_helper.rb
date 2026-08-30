# frozen_string_literal: true

#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Start coverage before anything under lib/ is loaded, or the methods that run
# at load time are reported as never run.
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.profiles.define "gem" do
    command_name "Specs"
  end
  SimpleCov.start "gem"
end

require "webmock/rspec"
require "tmpdir"
require "fileutils"

require "kitchen/driver/vra"
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |file| require file }

# These specs never reach a vRA appliance. Everything the driver does is turn
# kitchen.yml configuration into a vRA catalog request, and turn vRA's answers
# back into Test Kitchen state, so an outbound request from a spec is a mistake
# rather than a slow test.
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Fail if an example stubs a method the real object does not have. Almost
    # every driver method is a call into the vmware-vra gem, so without this a
    # rename there leaves the specs stubbing a method that no longer exists,
    # passing while the driver is broken.
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # No `describe` on bare objects and no `should` -- the RSpec 2 DSL, kept
  # alive only by monkey patches on Object and BasicObject.
  config.disable_monkey_patching!

  # Surface deprecations as failures rather than warnings that scroll past.
  config.raise_errors_for_deprecations!

  config.include VraApi

  config.filter_run_when_matching :focus

  # Run specs in random order to surface order dependencies. To debug one, fix
  # the order by passing the seed printed after each run:
  #     --seed 1234
  config.order = :random
  Kernel.srand config.seed
end
