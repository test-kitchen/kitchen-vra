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

require 'spec_helper'
require 'kitchen/driver/vra'
require 'kitchen/provisioner/dummy'
require 'kitchen/transport/dummy'
require 'kitchen/verifier/dummy'

describe Kitchen::Driver::Vra do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }
  let(:platform)      { Kitchen::Platform.new(name: 'fake_platform') }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:driver)        { Kitchen::Driver::Vra.new(config) }

  let(:config) do
    {
      base_url:      'https://vra.corp.local',
      username:      'myuser',
      password:      'mypassword',
      tenant:        'mytenant',
      verify_ssl:    true,
      cpus:          2,
      memory:        2048,
      requested_for: 'override_user@corp.local',
      notes:         'some notes',
      subtenant_id:  '160b473a-0ec9-473d-8156-28dd96c0b6b7',
      lease_days:    5,
      use_dns:       false
    }
  end

  let(:instance) do
    instance_double(Kitchen::Instance,
                    logger:    logger,
                    transport: transport,
                    platform:  platform,
                    to_str:    'instance_str')
  end

  before do
    allow(driver).to receive(:instance).and_return(instance)
  end

  it 'driver API version is 2' do
    expect(driver.diagnose_plugin[:api_version]).to eq(2)
  end

  describe '#name' do
    it 'has an overridden name' do
      expect(driver.name).to eq('vRA')
    end
  end

  describe '#create' do
    context 'when the server is already created' do
      let(:state) { { resource_id: '48959518-6a0d-46e1-8415-3749696b65f4' } }

      it 'does not submit a catalog request' do
        expect(driver).not_to receive(:request_server)
        driver.create(state)
      end
    end

    let(:state) { {} }
    let(:resource) do
      double('server1',
             id: 'e8706351-cf4c-4c12-acb7-c90cc683b22c',
             name: 'server1',
             ip_addresses: [ '1.2.3.4' ],
             vm?: true)
    end

    before do
      allow(driver).to receive(:request_server).and_return(resource)
      allow(driver).to receive(:wait_for_server)
    end

    it 'requests the server' do
      expect(driver).to receive(:request_server).and_return(resource)
      driver.create(state)
    end

    it 'sets the server ID in the state hash' do
      driver.create(state)
      expect(state[:resource_id]).to eq('e8706351-cf4c-4c12-acb7-c90cc683b22c')
    end

    it 'sets the hostname in the state hash' do
      allow(driver).to receive(:hostname_for).and_return('test_hostname')
      driver.create(state)
      expect(state[:hostname]).to eq('test_hostname')
    end

    it 'waits for the server to be ready' do
      expect(driver).to receive(:wait_for_server)
      driver.create(state)
    end
  end

  describe '#hostname_for' do
    let(:server) do
      double('server',
             id: 'test_id',
             name: 'test_hostname',
             ip_addresses: [ '1.2.3.4' ],
             vm?: true)
    end

    context 'when use_dns is true and dns_suffix is defined' do
      let(:config) do
        {
          use_dns:      true,
          dns_suffix:   'my.com'
        }
      end

      it 'returns the server name with suffix appended' do
        expect(driver.hostname_for(server)).to eq('test_hostname.my.com')
      end
    end

    context 'when use_dns is true' do
      let(:config) { { use_dns: true } }

      it 'raises an exception if the server name is nil' do
        allow(server).to receive(:name).and_return(nil)
        expect { driver.hostname_for(server) }.to raise_error(RuntimeError)
      end

      it 'returns the server name' do
        expect(driver.hostname_for(server)).to eq('test_hostname')
      end
    end

    context 'when use_dns is false' do
      it 'falls back to the server name if no IP address exists' do
        allow(server).to receive(:ip_addresses).and_return([])
        expect(driver).to receive(:warn)
        expect(driver.hostname_for(server)).to eq('test_hostname')
      end

      it 'returns the IP address if it exists' do
        expect(driver.hostname_for(server)).to eq('1.2.3.4')
      end
    end
  end

  describe '#request_server' do
    let(:submitted_request) { double('submitted_request') }
    let(:catalog_request)   { double('catalog_request') }
    let(:resource1) do
      double('server1',
             id: 'e8706351-cf4c-4c12-acb7-c90cc683b22c',
             name: 'server1',
             ip_addresses: [ '1.2.3.4' ],
             vm?: true)
    end
    let(:resource2) do
      double('server2',
             id: '9e2364cf-7af4-4b85-93fd-1f03ee2ac865',
             name: 'server2',
             ip_addresses: [ '4.3.2.1' ],
             vm?: true)
    end
    let(:resources) { [resource1] }

    before do
      allow(driver).to receive(:catalog_request).and_return(catalog_request)
      allow(catalog_request).to receive(:submit).and_return(submitted_request)
      allow(submitted_request).to receive(:id).and_return('74e26af9-2d2f-4889-a472-95dbcedb70b8')
      allow(submitted_request).to receive(:resources).and_return(resources)
      allow(submitted_request).to receive(:failed?).and_return(false)
      allow(driver).to receive(:wait_for_request).with(submitted_request)
    end

    it 'submits a catalog request' do
      expect(driver.catalog_request).to receive(:submit).and_return(submitted_request)
      driver.request_server
    end

    it 'waits for the request to complete' do
      expect(driver).to receive(:wait_for_request).with(submitted_request)
      driver.request_server
    end

    it 'raises an exception if the request failed' do
      allow(submitted_request).to receive(:failed?).and_return(true)
      allow(submitted_request).to receive(:completion_details).and_return('it failed')
      expect { driver.request_server }.to raise_error(RuntimeError)
    end

    describe 'getting the server from the request' do
      context 'when only one server is returned' do
        it 'does not raise an exception' do
          expect { driver.request_server }.not_to raise_error
        end
      end

      context 'when multiple servers are returned' do
        it 'raises an exception' do
          allow(submitted_request).to receive(:resources).and_return([ resource1, resource2 ])
          expect { driver.request_server }.to raise_error(RuntimeError)
        end
      end

      context 'when no servers are returned' do
        it 'raises an exception' do
          allow(submitted_request).to receive(:resources).and_return([])
          expect { driver.request_server }.to raise_error(RuntimeError)
        end
      end
    end

    it 'returns the the single server resource object' do
      expect(driver.request_server).to eq(resource1)
    end
  end

  describe '#wait_for_server' do
    let(:connection) { instance.transport.connection(state) }
    let(:state)      { {} }
    let(:resource1) do
      double('server1',
             id: 'test_id',
             name: 'server1',
             ip_addresses: [ '1.2.3.4' ],
             vm?: true)
    end

    before do
      allow(transport).to receive(:connection).and_return(connection)
      allow(driver).to receive(:sleep)
      allow(driver).to receive(:warn)
      allow(driver).to receive(:error)
    end

    it 'waits for the server to be ready' do
      expect(connection).to receive(:wait_until_ready)
      driver.wait_for_server(state, resource1)
    end

    context 'when an exception is caught and retries is 0' do
      let(:config) { { server_ready_retries: 0 } }

      it 'does not sleep and raises an exception' do
        allow(connection).to receive(:wait_until_ready).and_raise(Timeout::Error)
        expect(driver).not_to receive(:sleep)
        expect(driver).to receive(:error).with('Retries exceeded. Destroying server...')
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context 'when retries is 1 and it errors out twice' do
      let(:config) { { server_ready_retries: 1 } }

      it 'displays a warning, sleeps once, retries, errors, destroys, and raises' do
        expect(connection).to receive(:wait_until_ready).twice.and_raise(Timeout::Error)
        expect(driver).to receive(:warn).once.with('Sleeping 5 seconds and retrying...')
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:error).with('Retries exceeded. Destroying server...')
        expect(driver).to receive(:destroy).with(state)
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context 'when retries is 2 and it errors out all 3 times' do
      let(:config) { { server_ready_retries: 2 } }

      it 'displays 2 warnings, sleeps twice, retries, errors, destroys, and raises' do
        expect(connection).to receive(:wait_until_ready).exactly(3).times.and_raise(Timeout::Error)
        expect(driver).to receive(:warn).once.with('Sleeping 5 seconds and retrying...')
        expect(driver).to receive(:warn).once.with('Sleeping 10 seconds and retrying...')
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:sleep).once.with(10)
        expect(driver).to receive(:error).with('Retries exceeded. Destroying server...')
        expect(driver).to receive(:destroy).with(state)
        expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
      end
    end

    context 'when retries is 5, it errors out the first 2 tries, but works on the 3rd' do
      let(:config) { { server_ready_retries: 5 } }

      it 'displays 2 warnings, sleeps twice, retries, but does not destroy or raise' do
        expect(connection).to receive(:wait_until_ready).twice.and_raise(Timeout::Error)
        expect(connection).to receive(:wait_until_ready).once.and_return(true)
        expect(driver).to receive(:warn).once.with('Sleeping 5 seconds and retrying...')
        expect(driver).to receive(:warn).once.with('Sleeping 10 seconds and retrying...')
        expect(driver).to receive(:sleep).once.with(5)
        expect(driver).to receive(:sleep).once.with(10)
        expect(driver).not_to receive(:error)
        expect(driver).not_to receive(:destroy)
        expect { driver.wait_for_server(state, resource1) }.not_to raise_error
      end
    end

    context 'when retries is 7, always erroring' do
      let(:config) { { server_ready_retries: 8 } }

      it 'caps the delays at 30 seconds' do
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

  describe '#destroy' do
    let(:resource_id)     { '8c1a833a-5844-4100-b58c-9cab3543c958' }
    let(:state)           { { resource_id: resource_id } }
    let(:vra_client)      { double('vra_client') }
    let(:resources)       { double('resources') }
    let(:destroy_request) { double('destroy_request') }
    let(:resource) do
      double('server1',
             id: resource_id,
             name: 'server1',
             ip_addresses: [ '5.6.7.8' ],
             vm?: true)
    end

    before do
      allow(driver).to receive(:vra_client).and_return(vra_client)
      allow(driver).to receive(:wait_for_request).with(destroy_request)
      allow(vra_client).to receive(:resources).and_return(resources)
      allow(resources).to receive(:by_id).and_return(resource)
      allow(resource).to receive(:destroy).and_return(destroy_request)
      allow(destroy_request).to receive(:id).and_return('6da65982-7c33-4e6e-b346-fdf4bcbf01ab')
    end

    context 'when the resource is not created' do
      let(:state) { {} }
      it 'does not look up the resource if no resource ID exists' do
        expect(vra_client.resources).not_to receive(:by_id)
        driver.destroy(state)
      end
    end

    it 'looks up the resource record' do
      expect(vra_client.resources).to receive(:by_id).with(resource_id).and_return(resource)
      driver.destroy(state)
    end

    context 'when the resource record cannot be found' do
      it 'does not raise an exception' do
        allow(vra_client.resources).to receive(:by_id).with(resource_id).and_raise(Vra::Exception::NotFound)
        expect { driver.destroy(state) }.not_to raise_error
      end
    end

    describe 'creating the destroy request' do
      context 'when the destroy method or server is not found' do
        it 'does not raise an exception' do
          allow(resource).to receive(:destroy).and_raise(Vra::Exception::NotFound)
          expect { driver.destroy(state) }.not_to raise_error
        end
      end

      it 'calls #destroy on the server' do
        expect(resource).to receive(:destroy).and_return(destroy_request)
        driver.destroy(state)
      end
    end

    it 'waits for the destroy request to succeed' do
      expect(driver).to receive(:wait_for_request).with(destroy_request)
      driver.destroy(state)
    end
  end

  describe '#catalog_request' do
    let(:catalog_request) { double('catalog_request') }
    let(:vra_client)      { double('vra_client') }
    let(:catalog)         { double('catalog') }
    before do
      allow(driver).to receive(:vra_client).and_return(vra_client)
      allow(vra_client).to receive(:catalog).and_return(catalog)
      allow(catalog).to receive(:request).and_return(catalog_request)
      [ :cpus=, :memory=, :requested_for=, :lease_days=, :notes=, :subtenant_id=, :set_parameter ].each do |method|
        allow(catalog_request).to receive(method)
      end
    end

    it 'creates a catalog_request' do
      expect(vra_client.catalog).to receive(:request).and_return(catalog_request)
      driver.catalog_request
    end

    it 'sets all the standard parameters on the request' do
      expect(catalog_request).to receive(:cpus=).with(config[:cpus])
      expect(catalog_request).to receive(:memory=).with(config[:memory])
      expect(catalog_request).to receive(:requested_for=).with(config[:requested_for])
      expect(catalog_request).to receive(:lease_days=).with(config[:lease_days])
      expect(catalog_request).to receive(:notes=).with(config[:notes])
      expect(catalog_request).to receive(:subtenant_id=).with(config[:subtenant_id])
      driver.catalog_request
    end

    context 'when option parameters are not supplied' do
      let(:config) do
        {
          base_url:      'https://vra.corp.local',
          username:      'myuser',
          password:      'mypassword',
          tenant:        'mytenant',
          verify_ssl:    true,
          cpus:          2,
          memory:        2048,
          requested_for: 'override_user@corp.local'
        }
      end

      it 'does not attempt to set params on the catalog_request' do
        expect(catalog_request).not_to receive(:lease_days=)
        expect(catalog_request).not_to receive(:notes=)
        expect(catalog_request).not_to receive(:subtenant_id=)
        driver.catalog_request
      end
    end

    context 'when extra parameters are set' do
      let(:config) do
        {
          base_url:      'https://vra.corp.local',
          username:      'myuser',
          password:      'mypassword',
          tenant:        'mytenant',
          verify_ssl:    true,
          cpus:          2,
          memory:        2048,
          extra_parameters: { 'key1' => { type: 'string', value: 'value1' },
                              'key2' => { type: 'integer', value: 123 } }
        }
      end

      it 'sets extra parmeters' do
        expect(catalog_request).to receive(:set_parameter).with('key1', 'string', 'value1')
        expect(catalog_request).to receive(:set_parameter).with('key2', 'integer', 123)
        driver.catalog_request
      end
    end
  end

  describe '#vra_client' do
    it 'sets up a client object' do
      expect(Vra::Client).to receive(:new).with(base_url:   config[:base_url],
                                                username:   config[:username],
                                                password:   config[:password],
                                                tenant:     config[:tenant],
                                                verify_ssl: config[:verify_ssl])
      driver.vra_client
    end
  end

  describe '#wait_for_request' do
    before do
      # don't actually sleep
      allow(driver).to receive(:sleep)
    end

    context 'when the requests completes normally, 3 loops' do
      it 'only refreshes the request 3 times' do
        request = double('request')
        allow(request).to receive(:status)
        allow(request).to receive(:completed?).exactly(3).times.and_return(false, false, true)
        expect(request).to receive(:refresh).exactly(3).times

        driver.wait_for_request(request)
      end
    end

    context 'when the request is completed on the first loop' do
      it 'only refreshes the request 1 time' do
        request = double('request')
        allow(request).to receive(:status)
        allow(request).to receive(:completed?).once.and_return(true)
        expect(request).to receive(:refresh).once

        driver.wait_for_request(request)
      end
    end

    context 'when the timeout is exceeded' do
      it 'prints a warning and exits' do
        request = double('request')
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect { driver.wait_for_request(request) }.to raise_error(Timeout::Error)
      end
    end

    context 'when a non-timeout exception is raised' do
      it 'raises the original exception' do
        request = double('request')
        allow(request).to receive(:refresh).and_raise(RuntimeError)
        expect { driver.wait_for_request(request) }.to raise_error(RuntimeError)
      end
    end
  end
end
