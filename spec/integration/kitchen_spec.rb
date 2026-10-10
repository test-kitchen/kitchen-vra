# frozen_string_literal: true

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

require "spec_helper"
require "json"
require "tmpdir"
require "kitchen"
require "kitchen/driver/vra"
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

# Drives the driver the way `kitchen` drives it.
#
# The unit specs build the driver directly and stub out the vmware-vra gem, so
# between the two there is a lot of code nothing runs: the plugin lookup that
# turns `name: vra` into this class, the config merging Test Kitchen does
# before the driver ever sees a value, required_config validation, the lazy
# defaults that need an instance to resolve, and every line of vmware-vra that
# turns a catalog request into HTTP and an HTTP response back into a Resource.
#
# These specs load a real kitchen.yml with the real loader, take the driver
# Test Kitchen hands back, and run create, status and destroy against a vRA
# stubbed at the wire with WebMock. A vRA appliance cannot be stood up in CI,
# but everything on this side of the socket can be, and is.
RSpec.describe "the vra driver under Test Kitchen" do
  # These match spec/fixtures/kitchen.yml.
  let(:base_url)   { "https://vra.example.com" }
  let(:catalog_id) { "1536b95d-68fe-3c68-9417-46ed24bee3ef" }
  let(:deployment) { "48959518-6a0d-46e1-8415-3749696b65f4" }

  let(:kitchen_root) { Dir.mktmpdir("kitchen-vra-integration") }
  let(:kitchen_yml)  { File.expand_path("../fixtures/kitchen.yml", __dir__) }

  let(:kitchen_config) { kitchen_config_for(kitchen_yml) }

  let(:instance) { kitchen_config.instances.first }
  let(:driver)   { instance.driver }
  let(:state)    { {} }

  # The driver writes and removes .kitchen/cached_vra relative to the working
  # directory, so run inside the throwaway kitchen root rather than over a
  # developer's own cache.
  around do |example|
    Dir.chdir(kitchen_root) { example.run }
  end

  after { FileUtils.remove_entry(kitchen_root) }

  def kitchen_config_for(path)
    Kitchen::Config.new(
      kitchen_root: kitchen_root,
      log_root:     File.join(kitchen_root, ".kitchen", "logs"),
      log_level:    :error,
      loader:       Kitchen::Loader::YAML.new(
        project_config: path,
        process_local:  false,
        process_global: false
      )
    )
  end

  # vRA 8 authenticates in two steps -- credentials for a refresh token, then
  # the refresh token for an access token -- and re-checks the access token
  # before every call.
  def stub_authentication
    stub_request(:post, "#{base_url}/csp/gateway/am/api/login?access_token")
      .to_return(status: 200, body: JSON.dump(refresh_token: "refresh-token"))
    stub_request(:post, "#{base_url}/iaas/api/login")
      .to_return(status: 200, body: JSON.dump(token: "access-token"))
    stub_request(:head, "#{base_url}/csp/gateway/am/api/loggedin/user/orgs")
      .to_return(status: 200)
  end

  def stub_catalog_request(deployment_id: deployment)
    stub_request(:post, "#{base_url}/catalog/api/items/#{catalog_id}/request")
      .to_return(status: 200, body: JSON.dump([{ deploymentId: deployment_id }]))
  end

  def stub_deployment(*statuses)
    responses = statuses.map do |status|
      { status: 200, body: JSON.dump(id: deployment, name: "ubuntu-22.04", status: status) }
    end

    stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}")
      .to_return(*responses)
  end

  def stub_resources(*resources)
    stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/resources")
      .to_return(status: 200, body: JSON.dump(content: resources, totalPages: 1))
  end

  def vm(id: "res-1", name: "kitchen-ubuntu-2204", address: "10.0.0.42")
    {
      id: id,
      name: name,
      type: "Cloud.vSphere.Machine",
      properties: {
        address: address,
        networks: [{ name: "vlan100", address: address, mac_address: "00:50:56:00:00:01" }],
      },
    }
  end

  def network
    { id: "net-1", name: "vlan100", type: "Cloud.vSphere.Network", properties: {} }
  end

  describe "loading the plugin" do
    it "resolves `name: vra` to this driver" do
      expect(driver).to be_a(Kitchen::Driver::Vra)
    end

    it "reports this gem's version rather than Test Kitchen's" do
      expect(driver.diagnose_plugin[:version]).to eq(Kitchen::Driver::VRA_VERSION)
      expect(driver.diagnose_plugin[:version]).not_to eq(Kitchen::VERSION)
    end

    it "takes the settings from the driver block" do
      expect(driver[:base_url]).to eq(base_url)
      expect(driver[:image_mapping]).to eq("Ubuntu 22.04")
    end

    it "resolves the defaults that need an instance" do
      expect(driver[:deployment_name]).to eq("ubuntu-22.04")
    end

    it "refuses a config that is missing a required setting" do
      incomplete = File.join(kitchen_root, "kitchen.yml")
      File.write(incomplete, File.read(kitchen_yml).sub(/^  project_id:.*\n/, ""))

      expect { kitchen_config_for(incomplete).instances.first }
        .to raise_error(Kitchen::UserError, /project_id/)
    end
  end

  describe "kitchen create" do
    before do
      stub_authentication
      stub_catalog_request
      stub_deployment("CREATE_SUCCESSFUL")
      stub_resources(vm)
    end

    it "records the deployment vRA built" do
      driver.create(state)

      expect(state[:deployment_id]).to eq(deployment)
    end

    it "connects to the address vRA reported" do
      driver.create(state)

      expect(state[:hostname]).to eq("10.0.0.42")
    end

    it "passes the configured private key on to the transport" do
      driver.create(state)

      expect(state[:ssh_key]).to eq("/home/kitchen/.ssh/id_kitchen")
    end

    it "asks vRA for the configured catalog item, image and flavor" do
      driver.create(state)

      expect(
        a_request(:post, "#{base_url}/catalog/api/items/#{catalog_id}/request")
          .with { |request|
            body = JSON.parse(request.body)
            body["projectId"] == "6ba69375-79d5-42c3-a099-7d32739f71a7" &&
              body["deploymentName"] == "ubuntu-22.04" &&
              body["inputs"]["image"] == "Ubuntu 22.04" &&
              body["inputs"]["flavor"] == "Small"
          }
      ).to have_been_made
    end

    it "does not build a second deployment when one is already recorded" do
      state[:deployment_id] = deployment

      driver.create(state)

      expect(a_request(:post, "#{base_url}/catalog/api/items/#{catalog_id}/request")).not_to have_been_made
    end

    context "when the deployment is still building" do
      before { stub_deployment("CREATE_INPROGRESS", "CREATE_INPROGRESS", "CREATE_SUCCESSFUL") }

      it "waits for vRA to finish before handing the machine over" do
        driver.create(state)

        expect(state[:hostname]).to eq("10.0.0.42")
        expect(a_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}"))
          .to have_been_made.times(3)
      end
    end

    context "when the deployment contains more than the machine" do
      before { stub_resources(network, vm) }

      it "picks out the machine" do
        driver.create(state)

        expect(state[:hostname]).to eq("10.0.0.42")
      end
    end

    context "when the blueprint builds two machines" do
      before { stub_resources(vm, vm(id: "res-2", name: "second", address: "10.0.0.43")) }

      it "refuses rather than guessing which one to test" do
        expect { driver.create(state) }.to raise_error(RuntimeError, /more than one server/)
      end
    end

    context "when vRA reports no address for the machine" do
      before { stub_resources(vm(address: nil)) }

      it "falls back to the machine's name" do
        driver.create(state)

        expect(state[:hostname]).to eq("kitchen-ubuntu-2204")
      end
    end

    context "when vRA cannot build the deployment" do
      before do
        stub_deployment("CREATE_FAILED")
        stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/requests")
          .to_return(status: 200, body: JSON.dump(content: [{ id: "req-1", details: "no capacity in the project" }]))
      end

      it "reports what vRA said went wrong" do
        expect { driver.create(state) }.to raise_error(RuntimeError, /no capacity in the project/)
      end
    end
  end

  describe "kitchen list" do
    before do
      stub_authentication
      stub_deployment("CREATE_SUCCESSFUL")
    end

    it "says nothing about a suite that was never created" do
      expect(driver.status({})).to include(state: "unknown")
    end

    it "reports a built deployment as live" do
      expect(driver.status(deployment_id: deployment))
        .to include(live: true, state: "CREATE_SUCCESSFUL", resource_id: deployment)
    end

    context "when the deployment has been destroyed behind our back" do
      before do
        stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}")
          .to_return(status: 404, body: JSON.dump(errors: [{ message: "not found" }]))
      end

      it "says it does not know rather than failing the command" do
        expect(driver.status(deployment_id: deployment)).to include(state: "unknown")
      end
    end
  end

  describe "kitchen destroy" do
    let(:state) { { deployment_id: deployment } }

    before do
      stub_authentication
      stub_deployment("CREATE_SUCCESSFUL")
      stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/actions")
        .to_return(status: 200, body: JSON.dump([{ id: "action-delete", name: "Delete" }]))
      stub_request(:post, "#{base_url}/deployment/api/deployments/#{deployment}/requests")
        .to_return(status: 200, body: JSON.dump(id: "req-destroy", status: "SUCCESSFUL"))
      stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/requests/req-destroy?deleted=true")
        .to_return(status: 200, body: JSON.dump(id: "req-destroy", status: "SUCCESSFUL"))
    end

    it "submits the deployment's Delete action" do
      driver.destroy(state)

      expect(
        a_request(:post, "#{base_url}/deployment/api/deployments/#{deployment}/requests")
          .with { |request| JSON.parse(request.body)["actionId"] == "action-delete" }
      ).to have_been_made
    end

    it "waits for the destroy request to finish" do
      driver.destroy(state)

      expect(a_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/requests/req-destroy?deleted=true"))
        .to have_been_made
    end

    it "does nothing when the suite was never created" do
      driver.destroy({})

      expect(a_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}")).not_to have_been_made
    end

    context "when the deployment is already gone" do
      before do
        stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}")
          .to_return(status: 404, body: JSON.dump(errors: [{ message: "not found" }]))
      end

      it "treats it as destroyed rather than failing the command" do
        expect { driver.destroy(state) }.not_to raise_error
      end
    end

    context "when the deployment offers no Delete action" do
      before do
        stub_request(:get, "#{base_url}/deployment/api/deployments/#{deployment}/actions")
          .to_return(status: 200, body: JSON.dump([{ id: "action-poweroff", name: "PowerOff" }]))
      end

      it "treats it as destroyed rather than failing the command" do
        expect { driver.destroy(state) }.not_to raise_error
      end
    end
  end
end
