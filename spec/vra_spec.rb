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
      lease_days:    5
    }
  end

  let(:instance) do
    instance_double(Kitchen::Instance,
                    logger:    logger,
                    transport: transport,
                    platform:  platform,
                    to_str:    'instance_str'
                   )
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

    describe 'getting the IP address from the server' do
      context 'when no IP addresses are returned' do
        it 'raises an exception' do
          allow(resource).to receive(:ip_addresses).and_return([])
          expect { driver.create(state) }.to raise_error(RuntimeError)
        end
      end

      context 'when IP addresses are returned' do
        it 'sets the IP address as the hostname in the state hash' do
          driver.create(state)
          expect(state[:hostname]).to eq('1.2.3.4')
        end
      end
    end

    it 'waits for the server to be ready' do
      expect(driver).to receive(:wait_for_server)
      driver.create(state)
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

  describe '#wait_for_server_to_be_ready' do
    let(:connection) { instance.transport.connection(state) }
    let(:state)      { {} }
    let(:resource1) do
      double('server1',
             id: 'e8706351-cf4c-4c12-acb7-c90cc683b22c',
             name: 'server1',
             ip_addresses: [ '1.2.3.4' ],
             vm?: true)
    end

    before do
      allow(transport).to receive(:connection).and_return(connection)
    end

    it 'waits for the server to be ready' do
      expect(connection).to receive(:wait_until_ready)
      driver.wait_for_server(state, resource1)
    end

    it 'destroys the server and raises an exception if it fails to become ready' do
      allow(connection).to receive(:wait_until_ready).and_raise(Timeout::Error)
      expect(driver).to receive(:destroy).with(state)
      expect { driver.wait_for_server(state, resource1) }.to raise_error(Timeout::Error)
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
                              'key2' => { type: 'integer', value: 123 }
                            }
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
