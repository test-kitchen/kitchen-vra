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

RSpec.describe Kitchen::Driver::Vra do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }
  let(:platform)      { Kitchen::Platform.new(name: "fake_platform") }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:driver)        { described_class.new(config) }

  let(:config) do
    {
      base_url: "https://vra.corp.local",
      username: "myuser",
      password: "mypassword",
      domain: "mytenant.corp.com",
      project_id: "6ba69375-79d5-42c3-a099-7d32739f71a7",
      image_mapping: "VRA-nc-lnx-ce8.4-Docker",
      flavor_mapping: "Small",
      verify_ssl: true,
      use_dns: false,
      deployment_name: "test-instance",
      catalog_id: "1536b95d-68fe-3c68-9417-46ed24bee3ef",
    }
  end

  let(:instance) do
    instance_double(Kitchen::Instance,
      logger:    logger,
      transport: transport,
      platform:  platform,
      to_str:    "instance_str")
  end

  before do
    allow(driver).to receive(:instance).and_return(instance)
  end

  it "driver API version is 2" do
    expect(driver.diagnose_plugin[:api_version]).to eq(2)
  end

  describe "#name" do
    it "has an overridden name" do
      expect(driver.name).to eq("vRA")
    end
  end

  describe "configuration defaults" do
    let(:config) do
      {
        base_url: "https://vra.corp.local",
        domain: "mytenant.corp.com",
        project_id: "6ba69375-79d5-42c3-a099-7d32739f71a7",
        image_mapping: "VRA-nc-lnx-ce8.4-Docker",
        flavor_mapping: "Small",
      }
    end

    it "names the deployment after the platform under test" do
      expect(driver[:deployment_name]).to eq("fake_platform")
    end

    it "connects by IP address rather than by name" do
      expect(driver[:use_dns]).to be false
    end

    it "verifies the appliance certificate" do
      expect(driver[:verify_ssl]).to be true
    end

    describe "the private key" do
      let(:id_rsa) { File.expand_path("~/.ssh/id_rsa") }
      let(:id_dsa) { File.expand_path("~/.ssh/id_dsa") }

      before { allow(File).to receive(:exist?).and_return(false) }

      it "prefers an RSA key" do
        allow(File).to receive(:exist?).with(id_rsa).and_return(true)
        allow(File).to receive(:exist?).with(id_dsa).and_return(true)

        expect(driver[:private_key_path]).to eq(id_rsa)
      end

      it "falls back to a DSA key" do
        allow(File).to receive(:exist?).with(id_dsa).and_return(true)

        expect(driver[:private_key_path]).to eq(id_dsa)
      end

      it "is left unset when neither key exists" do
        expect(driver[:private_key_path]).to be_nil
      end
    end
  end

  describe "#create" do
    context "when the server is already created" do
      let(:state) { { deployment_id: "48959518-6a0d-46e1-8415-3749696b65f4" } }

      it "does not submit a catalog request" do
        expect(driver).not_to receive(:request_server)
        driver.create(state)
      end
    end

    let(:state)    { {} }
    let(:resource) { vra_resource(deployment_id: "e8706351-cf4c-4c12-acb7-c90cc683b22c") }

    before do
      allow(driver).to receive(:request_server).and_return(resource)
      allow(driver).to receive(:wait_for_server)
    end

    it "requests the server" do
      expect(driver).to receive(:request_server).and_return(resource)
      driver.create(state)
    end

    it "sets the server ID in the state hash" do
      driver.create(state)
      expect(state[:deployment_id]).to eq("e8706351-cf4c-4c12-acb7-c90cc683b22c")
    end

    it "sets the hostname in the state hash" do
      allow(driver).to receive(:hostname_for).and_return("test_hostname")
      driver.create(state)
      expect(state[:hostname]).to eq("test_hostname")
    end

    it "waits for the server to be ready" do
      expect(driver).to receive(:wait_for_server)
      driver.create(state)
    end

    context "when a private key is configured" do
      let(:config) { super().merge(private_key_path: "/home/me/.ssh/id_vra") }

      it "tells the transport which key to connect with" do
        driver.create(state)
        expect(state[:ssh_key]).to eq("/home/me/.ssh/id_vra")
      end
    end

    context "when no private key was found" do
      let(:config) { super().merge(private_key_path: nil) }

      it "leaves the transport to work out how to connect" do
        driver.create(state)
        expect(state).not_to have_key(:ssh_key)
      end
    end
  end

  describe "#hostname_for" do
    let(:server) { vra_resource(deployment_id: "test_id", name: "test_hostname") }

    context "when use_dns is true and dns_suffix is defined" do
      let(:config) do
        {
          use_dns: true,
          dns_suffix: "my.com",
        }
      end

      it "returns the server name with suffix appended" do
        expect(driver.hostname_for(server)).to eq("test_hostname.my.com")
      end
    end

    context "when use_dns is true" do
      let(:config) { { use_dns: true } }

      it "raises an exception if the server name is nil" do
        expect { driver.hostname_for(vra_resource(name: nil)) }.to raise_error(RuntimeError)
      end

      it "returns the server name" do
        expect(driver.hostname_for(server)).to eq("test_hostname")
      end

      it "does not go looking for an IP address" do
        expect(server).not_to receive(:ip_address)
        driver.hostname_for(server)
      end
    end

    context "when use_dns is false" do
      it "falls back to the server name if no IP address exists" do
        expect(driver).to receive(:warn)
        expect(driver.hostname_for(vra_resource(ip_address: nil))).to eq("test-server")
      end

      it "returns the IP address if it exists" do
        expect(driver.hostname_for(server)).to eq("1.2.3.4")
      end
    end
  end

  describe "#request_server" do
    let(:deployment)      { vra_deployment(id: "74e26af9-2d2f-4889-a472-95dbcedb70b8", resources: resources) }
    let(:catalog_request) { vra_deployment_request(submit: deployment) }
    let(:resource1)       { vra_resource(id: "e8706351-cf4c-4c12-acb7-c90cc683b22c", name: "server1") }
    let(:resource2)       { vra_resource(id: "9e2364cf-7af4-4b85-93fd-1f03ee2ac865", name: "server2") }
    let(:resources)       { [resource1] }

    before do
      allow(driver).to receive(:catalog_request).and_return(catalog_request)
      allow(driver).to receive(:wait_for_request).with(deployment)
    end

    it "submits a catalog request" do
      expect(catalog_request).to receive(:submit).and_return(deployment)
      driver.request_server
    end

    it "waits for the request to complete" do
      expect(driver).to receive(:wait_for_request).with(deployment)
      driver.request_server
    end

    it "raises an exception if the request failed" do
      allow(deployment).to receive(:failed?).and_return(true)
      allow(deployment).to receive(:completion_details).and_return("it failed")

      expect { driver.request_server }.to raise_error(RuntimeError, /it failed/)
    end

    describe "getting the server from the request" do
      context "when only one server is returned" do
        it "does not raise an exception" do
          expect { driver.request_server }.not_to raise_error
        end
      end

      context "when multiple servers are returned" do
        let(:resources) { [resource1, resource2] }

        it "raises an exception" do
          expect { driver.request_server }.to raise_error(RuntimeError, /more than one server/)
        end
      end

      context "when no servers are returned" do
        let(:resources) { [] }

        it "raises an exception" do
          expect { driver.request_server }.to raise_error(RuntimeError, /did not create any servers/)
        end
      end

      context "when the deployment also contains things that are not VMs" do
        let(:resources) { [vra_resource(id: "net-1", vm?: false), resource1] }

        it "picks out the one VM" do
          expect(driver.request_server).to eq(resource1)
        end
      end
    end

    it "returns the the single server resource object" do
      expect(driver.request_server).to eq(resource1)
    end

    context "when unique_name is set" do
      let(:config) { super().merge(unique_name: true) }

      it "reports the name vRA will give the deployment" do
        allow(driver).to receive(:info)

        driver.request_server

        expect(driver).to have_received(:info)
          .with("Deployment name is deployment_74e26af9-2d2f-4889-a472-95dbcedb70b8")
      end
    end
  end

  describe "#wait_for_server" do
    let(:connection) { instance.transport.connection(state) }
    let(:state)      { {} }
    let(:resource1)  { vra_resource(id: "test_id", name: "server1") }

    before do
      allow(transport).to receive(:connection).and_return(connection)
      allow(driver).to receive(:sleep)
      allow(driver).to receive(:warn)
      allow(driver).to receive(:error)
    end

    it "waits for the server to be ready" do
      expect(connection).to receive(:wait_until_ready)
      driver.wait_for_server(state, resource1)
    end

    context "when an exception is caught and retries is 0" do
      let(:config) { { server_ready_retries: 0 } }

      it "does not sleep and raises an exception" do
        allow(connection).to receive(:wait_until_ready).and_raise(Timeout::Error)
        expect(driver).not_to receive(:sleep)
        expect(driver).to receive(:error).with("Retries exceeded. Destroying server...")
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context "when retries is 1 and it errors out twice" do
      let(:config) { { server_ready_retries: 1 } }

      it "displays a warning, sleeps once, retries, errors, destroys, and raises" do
        expect(connection).to receive(:wait_until_ready).twice.and_raise(Timeout::Error)
        expect(driver).to receive(:warn).once.with("Sleeping 5 seconds and retrying...")
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:error).with("Retries exceeded. Destroying server...")
        expect(driver).to receive(:destroy).with(state)
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context "when retries is 2 and it errors out all 3 times" do
      let(:config) { { server_ready_retries: 2 } }

      it "displays 2 warnings, sleeps twice, retries, errors, destroys, and raises" do
        expect(connection).to receive(:wait_until_ready).exactly(3).times.and_raise(Timeout::Error)
        expect(driver).to receive(:warn).once.with("Sleeping 5 seconds and retrying...")
        expect(driver).to receive(:warn).once.with("Sleeping 10 seconds and retrying...")
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:sleep).once.with(10)
        expect(driver).to receive(:error).with("Retries exceeded. Destroying server...")
        expect(driver).to receive(:destroy).with(state)
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context "when retries is 5, it errors out the first 2 tries, but works on the 3rd" do
      let(:config) { { server_ready_retries: 5 } }

      it "displays 2 warnings, sleeps twice, retries, but does not destroy or raise" do
        expect(connection).to receive(:wait_until_ready).twice.and_raise(Timeout::Error)
        expect(connection).to receive(:wait_until_ready).once.and_return(true)
        expect(driver).to receive(:warn).once.with("Sleeping 5 seconds and retrying...")
        expect(driver).to receive(:warn).once.with("Sleeping 10 seconds and retrying...")
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:sleep).once.with(10)
        expect(driver).not_to receive(:error)
        expect(driver).not_to receive(:destroy)
        expect { driver.wait_for_server(state, resource1) }.not_to raise_error
      end
    end

    context "when retries is 7, always erroring" do
      let(:config) { { server_ready_retries: 8 } }

      it "caps the delays at 30 seconds" do
        expect(connection).to receive(:wait_until_ready).exactly(9).times.and_raise(Timeout::Error)
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:sleep).once.with(10)
        expect(driver).to receive(:sleep).once.with(15)
        expect(driver).to receive(:sleep).once.with(20)
        expect(driver).to receive(:sleep).once.with(25)
        expect(driver).to receive(:sleep).exactly(3).times.with(30)
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end
  end

  describe "#status" do
    let(:deployments) { instance_double(Vra::Deployments) }
    let(:client)      { vra_client(deployments: deployments) }

    before { allow(driver).to receive(:vra_client).and_return(client) }

    it "reports an unknown status when state names no deployment" do
      expect(driver.status({})).to include(live: nil, state: "unknown")
    end

    it "reports an unknown status when vRA has never heard of the deployment" do
      allow(deployments).to receive(:by_id).with("gone")
        .and_raise(Vra::Exception::NotFound.new("nope"))

      expect(driver.status(deployment_id: "gone")).to include(state: "unknown")
    end

    it "reports a successfully created deployment as live" do
      allow(deployments).to receive(:by_id).with("dep-1").and_return(vra_deployment)

      expect(driver.status(deployment_id: "dep-1")).to include(
        live: true, state: "CREATE_SUCCESSFUL", source: "driver",
        resource_id: "dep-1"
      )
    end

    it "stamps when the check happened" do
      allow(deployments).to receive(:by_id).and_return(vra_deployment)

      expect(driver.status(deployment_id: "dep-1")[:checked_at])
        .to match(/\A\d{4}-\d{2}-\d{2}T/)
    end

    it "reports a deployment still building as not live" do
      allow(deployments).to receive(:by_id).and_return(vra_deployment(status: "CREATE_INPROGRESS"))

      expect(driver.status(deployment_id: "dep-1"))
        .to include(live: false, state: "CREATE_INPROGRESS")
    end

    it "names a failed deployment rather than reporting a bare false" do
      allow(deployments).to receive(:by_id).and_return(vra_deployment(status: "CREATE_FAILED", failed?: true))

      expect(driver.status(deployment_id: "dep-1"))
        .to include(live: false, state: "CREATE_FAILED")
    end

    it "reports an unknown status when vRA cannot be reached" do
      allow(deployments).to receive(:by_id).and_raise(StandardError.new("boom"))

      expect(driver.status(deployment_id: "dep-1")).to include(state: "unknown")
    end
  end

  describe "#destroy" do
    let(:deployment_id)   { "8c1a833a-5844-4100-b58c-9cab3543c958" }
    let(:state)           { { deployment_id: deployment_id } }
    let(:deployments)     { instance_double(Vra::Deployments) }
    let(:client)          { vra_client(deployments: deployments) }
    let(:destroy_request) { vra_request(id: "6da65982-7c33-4e6e-b346-fdf4bcbf01ab") }
    let(:deployment)      { vra_deployment(id: deployment_id, destroy: destroy_request) }

    before do
      allow(driver).to receive(:vra_client).and_return(client)
      allow(driver).to receive(:wait_for_request).with(destroy_request)
      allow(deployments).to receive(:by_id).and_return(deployment)
    end

    context "when the resource is not created" do
      let(:state) { {} }

      it "does not look up the resource if no resource ID exists" do
        expect(deployments).not_to receive(:by_id)
        driver.destroy(state)
      end
    end

    it "looks up the resource record" do
      expect(deployments).to receive(:by_id).with(deployment_id).and_return(deployment)
      driver.destroy(state)
    end

    context "when the resource record cannot be found" do
      it "does not raise an exception" do
        allow(deployments).to receive(:by_id).with(deployment_id).and_raise(Vra::Exception::NotFound)
        expect { driver.destroy(state) }.not_to raise_error
      end
    end

    describe "creating the destroy request" do
      context "when the destroy method or server is not found" do
        it "does not raise an exception" do
          allow(deployment).to receive(:destroy).and_raise(Vra::Exception::NotFound)
          expect { driver.destroy(state) }.not_to raise_error
        end
      end

      it "calls #destroy on the server" do
        expect(deployment).to receive(:destroy).and_return(destroy_request)
        driver.destroy(state)
      end
    end

    it "waits for the destroy request to succeed" do
      expect(driver).to receive(:wait_for_request).with(destroy_request)
      driver.destroy(state)
    end

    describe "the cached credentials" do
      let(:cache_dir) { Dir.mktmpdir("kitchen-vra-spec") }

      around { |example| Dir.chdir(cache_dir) { example.run } }
      after  { FileUtils.remove_entry(cache_dir) }

      it "removes the cache file left behind by a previous run" do
        FileUtils.mkdir_p(".kitchen")
        File.write(".kitchen/cached_vra", "cached")

        driver.destroy(state)

        expect(File.exist?(".kitchen/cached_vra")).to be false
      end

      it "does not claim to have removed a cache file that was never written" do
        expect(driver).not_to receive(:info).with(/Removed.*cached/i)

        driver.destroy(state)
      end
    end
  end

  describe "#catalog_request" do
    let(:deployment_request) { vra_deployment_request }
    let(:catalog)            { instance_double(Vra::Catalog, request: deployment_request) }
    let(:client)             { vra_client(catalog: catalog) }

    before { allow(driver).to receive(:vra_client).and_return(client) }

    it "creates a catalog_request" do
      expect(catalog).to receive(:request).and_return(deployment_request)
      driver.catalog_request
    end

    it "asks for the configured image, flavor, project and version" do
      expect(catalog).to receive(:request).with(
        "1536b95d-68fe-3c68-9417-46ed24bee3ef",
        hash_including(
          image_mapping:  "VRA-nc-lnx-ce8.4-Docker",
          flavor_mapping: "Small",
          project_id:     "6ba69375-79d5-42c3-a099-7d32739f71a7",
          version:        nil
        )
      ).and_return(deployment_request)

      driver.catalog_request
    end

    it "names the deployment" do
      expect(catalog).to receive(:request)
        .with(anything, hash_including(name: "test-instance"))
        .and_return(deployment_request)

      driver.catalog_request
    end

    context "when unique_name is set" do
      let(:config) { super().merge(unique_name: true) }

      it "leaves vRA to name the deployment after the request" do
        expect(catalog).to receive(:request)
          .with(anything, hash_excluding(:name))
          .and_return(deployment_request)

        driver.catalog_request
      end
    end

    context "when the catalog item is named rather than identified" do
      let(:config) do
        super().reject { |key, _value| key == :catalog_id }
          .merge(catalog_name: "Ubuntu Server")
      end

      it "looks the name up and requests the ID it resolves to" do
        allow(catalog).to receive(:fetch_catalog_items).with("Ubuntu Server")
          .and_return([vra_catalog_item(id: "cat-9")])
        expect(catalog).to receive(:request).with("cat-9", anything).and_return(deployment_request)

        driver.catalog_request
      end

      context "when the name matches nothing in the catalog" do
        before do
          allow(catalog).to receive(:fetch_catalog_items).and_return([])
          allow(driver).to receive(:error)
        end

        it "fails rather than requesting an unknown catalog item" do
          expect { driver.catalog_request }
            .to raise_error(Kitchen::InstanceFailure, /without a valid catalog/)
        end

        it "says which name it could not resolve" do
          expect { driver.catalog_request }.to raise_error(Kitchen::InstanceFailure)

          expect(driver).to have_received(:error).with(/Ubuntu Server/)
        end
      end
    end

    context "when neither a catalog ID nor a catalog name is given" do
      let(:config) { super().reject { |key, _value| key == :catalog_id } }

      it "fails before talking to vRA" do
        expect(catalog).not_to receive(:request)
        expect { driver.catalog_request }.to raise_error(Kitchen::InstanceFailure)
      end
    end

    context "when option parameters are not supplied" do
      it "does not attempt to set params on the catalog_request" do
        expect(deployment_request).not_to receive(:set_parameters)
        driver.catalog_request
      end
    end

    context "when extra parameters are set" do
      let(:config) do
        super().merge(
          extra_parameters: {
            "key1" => { type: "string", value: "value1" },
            "key2" => { type: "integer", value: 123 },
          }
        )
      end

      it "sets extra parameters" do
        expect(deployment_request).to receive(:set_parameters).with("key1", { type: "string", value: "value1" })
        expect(deployment_request).to receive(:set_parameters).with("key2", { type: "integer", value: 123 })
        driver.catalog_request
      end
    end
  end

  describe "#vra_client" do
    let(:client) { vra_client }

    it "sets up a client object" do
      expect(Vra::Client).to receive(:new).with(base_url:   config[:base_url],
        username:   config[:username],
        password:   config[:password],
        domain:     config[:domain],
        verify_ssl: config[:verify_ssl])
      driver.vra_client
    end

    it "builds the client once and hands the same one back" do
      expect(Vra::Client).to receive(:new).once.and_return(client)

      expect(driver.vra_client).to eq(client)
      expect(driver.vra_client).to eq(client)
    end

    context "when cache_credentials is enabled" do
      let(:config) { super().merge(cache_credentials: true) }

      before { allow(driver).to receive(:c_save) }

      it "does not prompt for credentials it already has" do
        allow(Vra::Client).to receive(:new).and_return(client)
        expect(driver).not_to receive(:ask)

        driver.vra_client
      end
    end

    context "when the client cannot be built" do
      before do
        allow(driver).to receive(:warn)
        allow(driver).to receive(:check_config)
      end

      it "re-prompts for the credentials and tries once more" do
        attempts = 0
        allow(Vra::Client).to receive(:new) do
          attempts += 1
          raise ArgumentError, "Username and password are required" if attempts == 1

          client
        end

        expect(driver.vra_client).to eq(client)
        expect(driver).to have_received(:check_config).with(true)
      end

      it "raises rather than handing back something that is not a client" do
        allow(Vra::Client).to receive(:new)
          .and_raise(ArgumentError, "Username and password are required")

        expect { driver.vra_client }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#wait_for_request" do
    before do
      # don't actually sleep
      allow(driver).to receive(:sleep)
    end

    context "when the requests completes normally, 3 loops" do
      it "only refreshes the request 3 times" do
        request = vra_request(status: nil)
        allow(request).to receive(:completed?).and_return(false, false, true)

        driver.wait_for_request(request)

        expect(request).to have_received(:refresh).exactly(3).times
      end
    end

    context "when the request is completed on the first loop" do
      it "only refreshes the request 1 time" do
        request = vra_request(status: nil)

        driver.wait_for_request(request)

        expect(request).to have_received(:refresh).once
      end
    end

    it "reports a status once, not on every poll" do
      request = vra_request(status: "IN_PROGRESS")
      allow(request).to receive(:completed?).and_return(false, false, true)
      allow(driver).to receive(:info)

      driver.wait_for_request(request)

      expect(driver).to have_received(:info).with("Current request status: IN_PROGRESS").once
    end

    context "with a slower refresh rate configured" do
      let(:config) { super().merge(request_refresh_rate: 10) }

      it "waits that long between polls" do
        request = vra_request(status: nil)
        allow(request).to receive(:completed?).and_return(false, true)
        expect(driver).to receive(:sleep).with(10)

        driver.wait_for_request(request)
      end
    end

    context "when the timeout is exceeded" do
      it "prints a warning and exits" do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        allow(driver).to receive(:error)

        expect { driver.wait_for_request(vra_request) }.to raise_error(Timeout::Error)
        expect(driver).to have_received(:error).with(/did not complete in 600 seconds/)
      end
    end

    context "when a non-timeout exception is raised" do
      it "raises the original exception" do
        request = vra_request
        allow(request).to receive(:refresh).and_raise(RuntimeError)

        expect { driver.wait_for_request(request) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "credential caching" do
    let(:cache_dir)  { Dir.mktmpdir("kitchen-vra-spec") }
    let(:cache_file) { File.join(cache_dir, ".kitchen", "cached_vra") }

    # c_save/c_load address the cache by a path relative to the working
    # directory, so each example runs inside a throwaway directory.
    around do |example|
      Dir.chdir(cache_dir) { example.run }
    end

    after { FileUtils.remove_entry(cache_dir) }

    # A second driver reading the cache the first one wrote, which is what the
    # next `kitchen` run is.
    def reader(overrides = {})
      described_class.new(config.merge(overrides).reject { |k, _v| %i{username password}.include?(k) })
        .tap { |driver| allow(driver).to receive(:instance).and_return(instance) }
    end

    describe "#c_save" do
      it "creates the cache file" do
        driver.c_save
        expect(File.exist?(cache_file)).to be true
      end

      it "creates the .kitchen directory when it does not exist" do
        expect { driver.c_save }.to change { Dir.exist?(File.join(cache_dir, ".kitchen")) }.from(false).to(true)
      end

      it "writes the file readable only by its owner" do
        driver.c_save
        expect(File.stat(cache_file).mode & 0o777).to eq(0o600)
      end

      it "does not write the password in the clear" do
        driver.c_save
        expect(File.read(cache_file)).not_to include("mypassword")
      end

      it "does not write the username in the clear either" do
        driver.c_save
        expect(File.read(cache_file)).not_to include("myuser")
      end

      it "reports a cache it could not write rather than failing the run" do
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
        expect(driver).to receive(:warn).with(/Unable to save credentials/)

        expect { driver.c_save }.not_to raise_error
      end
    end

    describe "#c_load" do
      it "restores credentials written by #c_save" do
        driver.c_save

        loader = reader
        loader.c_load

        expect(loader[:username]).to eq("myuser")
        expect(loader[:password]).to eq("mypassword")
      end

      it "does nothing when no cache file exists" do
        driver.c_load
        expect(driver[:username]).to eq("myuser")
      end

      it "refuses a cache written against a different base_url" do
        driver.c_save

        other = reader(base_url: "https://other.corp.local")
        expect(other).to receive(:warn).with(/Failed to load cached credentials/)
        other.c_load

        expect(other[:username]).to be_nil
        expect(other[:password]).to be_nil
      end

      it "refuses a corrupted cache rather than returning garbage" do
        driver.c_save
        File.write(cache_file, File.read(cache_file).succ)

        loader = reader
        expect(loader).to receive(:warn).with(/Failed to load cached credentials/)
        loader.c_load

        expect(loader[:username]).to be_nil
      end

      it "refuses a cache written in a layout it does not recognize" do
        FileUtils.mkdir_p(File.dirname(cache_file))
        File.write(cache_file, "v0:whatever")

        loader = reader
        expect(loader).to receive(:warn).with(/unrecognized cache format/)
        loader.c_load

        expect(loader[:username]).to be_nil
      end
    end

    describe "#check_config" do
      it "keeps the credentials it was configured with" do
        allow(driver).to receive(:ask)

        driver.check_config

        expect(driver[:username]).to eq("myuser")
        expect(driver[:password]).to eq("mypassword")
        expect(driver).not_to have_received(:ask)
      end

      it "asks again when told to, even though it has credentials" do
        allow(driver).to receive(:ask).and_return("newuser", "newpass")

        driver.check_config(true)

        expect(driver[:username]).to eq("newuser")
        expect(driver[:password]).to eq("newpass")
      end

      it "does not write a cache file unless asked to" do
        driver.check_config

        expect(File.exist?(cache_file)).to be false
      end

      context "when cache_credentials is enabled" do
        let(:config) { super().merge(cache_credentials: true) }

        it "writes the credentials out for the next run" do
          driver.check_config

          expect(File.exist?(cache_file)).to be true
        end
      end

      context "when the config names no credentials" do
        it "reads them from the environment" do
          stub_const("ENV", ENV.to_hash.merge("VRA_USER_NAME" => "envuser",
            "VRA_USER_PASSWORD" => "envpass"))
          loader = reader
          expect(loader).not_to receive(:ask)

          loader.check_config

          expect(loader[:username]).to eq("envuser")
          expect(loader[:password]).to eq("envpass")
        end

        it "uses the cache instead of prompting" do
          driver.c_save

          stub_const("ENV", ENV.to_hash.reject { |key, _v| key.start_with?("VRA_USER_") })
          loader = reader
          expect(loader).not_to receive(:ask)

          loader.check_config

          expect(loader[:username]).to eq("myuser")
          expect(loader[:password]).to eq("mypassword")
        end

        it "prompts as a last resort" do
          stub_const("ENV", ENV.to_hash.reject { |key, _v| key.start_with?("VRA_USER_") })
          loader = reader
          allow(loader).to receive(:ask).and_return("askeduser", "askedpass")

          loader.check_config

          expect(loader[:username]).to eq("askeduser")
          expect(loader[:password]).to eq("askedpass")
        end
      end
    end
  end
end
