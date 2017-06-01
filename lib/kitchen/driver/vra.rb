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

require 'kitchen'
require 'highline/import'
require 'openssl'
require 'base64'
require 'digest/sha1'
require 'vra'
require_relative 'vra_version'

module Kitchen
  module Driver
    class Vra < Kitchen::Driver::Base # rubocop:disable Metrics/ClassLength
      kitchen_driver_api_version 2
      plugin_version Kitchen::Driver::VRA_VERSION

      default_config :username, ''
      default_config :password, ''
      required_config :base_url
      required_config :tenant
      required_config :catalog_id

      default_config :subtenant, nil
      default_config :verify_ssl, true
      default_config :request_timeout, 600
      default_config :request_refresh_rate, 2
      default_config :server_ready_retries, 1
      default_config :cpus, 1
      default_config :memory, 1024
      default_config :requested_for do |driver|
        driver[:username]
      end
      default_config :lease_days, nil
      default_config :notes, nil
      default_config :cache_credentials, false
      default_config :extra_parameters, {}
      default_config :private_key_path do
        %w(id_rsa id_dsa).map do |key|
          file = File.expand_path("~/.ssh/#{key}")
          file if File.exist?(file)
        end.compact.first
      end
      default_config :use_dns, false
      default_config :dns_suffix, nil

      def name
        'vRA'
      end

      def check_config(force_change = false)
        c_load
        config[:username] = ask('Enter Username: ') if config[:username].eql?('') || force_change
        config[:password] = ask('Enter password: ') { |q| q.echo = '*' } if config[:password].eql?('') || force_change
        c_save
      end

      def c_save
        cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
        cipher.encrypt
        cipher.key = Digest::SHA1.hexdigest(config[:base_url])
        iv = cipher.random_iv
        cipher.iv = iv
        username = cipher.update(config[:username]) + cipher.final
        password = cipher.update(config[:password]) + cipher.final
        output = "#{Base64.encode64(iv).strip!}:#{Base64.encode64(username).strip!}:#{Base64.encode64(password).strip!}"
        file = File.open('.kitchen/cached_vra', 'w')
        file.write(output)
        file.close
      rescue
        puts 'Unable to save credentials'
      end

      def c_load
        if File.exist? '.kitchen/cached_vra'
          encrypted = File.read('.kitchen/cached_vra')
          iv = Base64.decode64(encrypted.split(':')[0] + '\n')
          username = Base64.decode64(encrypted.split(':')[1] + "\n")
          password = Base64.decode64(encrypted.split(':')[2] + "\n")
          cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
          cipher.decrypt
          cipher.key = Digest::SHA1.hexdigest(config[:base_url])
          cipher.iv = iv
          config[:username] = cipher.update(username) + cipher.final
          config[:password] = cipher.update(password) + cipher.final
        end
      rescue
        puts 'Failed to load cached credentials'
      end

      def create(state)
        return if state[:resource_id]

        server = request_server
        state[:resource_id] = server.id
        state[:hostname]    = hostname_for(server)
        state[:ssh_key]     = config[:private_key_path] unless config[:private_key_path].nil?

        wait_for_server(state, server)
        info("Server #{server.id} (#{server.name}) ready.")
      end

      def hostname_for(server)
        if config[:use_dns]
          raise 'No server name returned for the vRA request' if server.name.nil?
          return config[:dns_suffix] ? "#{server.name}.#{config[:dns_suffix]}" : server.name
        end

        ip_address = server.ip_addresses.first
        if ip_address.nil?
          warn("Server #{server.id} has no IP address. Falling back to server name (#{server.name})...")
          server.name
        else
          ip_address
        end
      end

      def request_server
        info('Building vRA catalog request...')
        submitted_request = catalog_request.submit
        info("Catalog request #{submitted_request.id} submitted.")

        wait_for_request(submitted_request)
        raise "The vRA request failed: #{submitted_request.completion_details}" if submitted_request.failed?

        servers = submitted_request.resources.select(&:vm?)
        raise 'The vRA request created more than one server. The catalog blueprint should only return one.' if servers.size > 1
        raise 'the vRA request did not create any servers.' if servers.size.zero?

        servers.first
      end

      def wait_for_server(state, server)
        info("Server #{server.id} (#{server.name}) created. Waiting until ready...")

        try = 0
        sleep_time = 0

        begin
          instance.transport.connection(state).wait_until_ready
        rescue => e
          warn("Server #{server.id} (#{server.name}) not reachable: #{e.class} -- #{e.message}")

          try += 1
          sleep_time += 5 if sleep_time < 30

          if try > config[:server_ready_retries]
            error('Retries exceeded. Destroying server...')
            destroy(state)
            raise
          else
            warn("Sleeping #{sleep_time} seconds and retrying...")
            sleep sleep_time
            retry
          end
        end
      end

      def destroy(state)
        return if state[:resource_id].nil?

        begin
          server = vra_client.resources.by_id(state[:resource_id])
        rescue ::Vra::Exception::NotFound
          warn("No server found with ID #{state[:resource_id]}, assuming it has been destroyed already.")
          return
        end

        begin
          destroy_request = server.destroy
        rescue ::Vra::Exception::NotFound
          info('Server not found, or no destroy action available, perhaps because it is already destroyed.')
          return
        end
        info("Destroy request #{destroy_request.id} submitted.")
        wait_for_request(destroy_request)
        info('Destroy request complete.')
      end

      def catalog_request
        catalog_request = vra_client.catalog.request(config[:catalog_id])

        catalog_request.cpus          = config[:cpus]
        catalog_request.memory        = config[:memory]
        catalog_request.requested_for = config[:requested_for]
        catalog_request.lease_days    = config[:lease_days]    unless config[:lease_days].nil?
        catalog_request.notes         = config[:notes]         unless config[:notes].nil?
        catalog_request.subtenant_id  = config[:subtenant_id]  unless config[:subtenant_id].nil?

        config[:extra_parameters].each do |key, value_data|
          catalog_request.set_parameter(key, value_data[:type], value_data[:value])
        end

        catalog_request
      end

      def vra_client
        check_config false if config[:cache_credentials]
        @client ||= ::Vra::Client.new(
          base_url:   config[:base_url],
          username:   config[:username],
          password:   config[:password],
          tenant:     config[:tenant],
          verify_ssl: config[:verify_ssl]
        )
      rescue => _e
        check_config true
      end

      def wait_for_request(request)
        # config = check_config config

        last_status = ''
        wait_time   = config[:request_timeout]
        sleep_time  = config[:request_refresh_rate]
        Timeout.timeout(wait_time) do
          loop do
            request.refresh
            break if request.completed?

            unless last_status == request.status
              last_status = request.status
              info("Current request status: #{request.status}")
            end

            sleep sleep_time
          end
        end
      rescue Timeout::Error
        error("Request did not complete in #{wait_time} seconds. Check the Requests tab in the vRA UI for more information.")
        raise
      end
    end
  end
end
