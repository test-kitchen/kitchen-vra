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

require "kitchen"
require "highline/import"
require "openssl" unless defined?(OpenSSL)
require "base64" unless defined?(Base64)
require "digest/sha1" unless defined?(Digest::SHA1)
require "vra"
require_relative "vra_version"

module Kitchen
  # Test Kitchen's driver plugins.
  module Driver
    # Test Kitchen driver for VMware vRealize Automation (vRA) 8.x.
    #
    # Unlike a cloud driver that creates a machine directly, this driver
    # submits a request against a vRA catalog item and waits for vRA's own
    # automation to build a deployment. The blueprint behind that catalog item
    # decides what gets built; this driver only supplies the image, flavor,
    # and project, then waits for a single VM to come back.
    #
    # The blueprint must return exactly one VM. A blueprint returning several,
    # or none, fails the +create+ rather than guessing which one to test.
    #
    # @see https://www.vmware.com/products/vrealize-automation.html vRealize Automation
    class Vra < Kitchen::Driver::Base # rubocop:disable Metrics/ClassLength
      kitchen_driver_api_version 2
      plugin_version Kitchen::Driver::VRA_VERSION

      default_config :username, nil
      default_config :password, nil
      required_config :base_url
      required_config :domain
      required_config :project_id
      required_config :image_mapping
      required_config :flavor_mapping

      default_config :tenant, nil
      default_config :version, nil
      default_config :catalog_id, nil
      default_config :catalog_name, nil

      default_config :verify_ssl, true
      default_config :request_timeout, 600
      default_config :request_refresh_rate, 2
      default_config :server_ready_retries, 1
      default_config :unique_name, false
      default_config :deployment_name do |driver|
        driver&.instance&.platform&.name
      end
      default_config :cache_credentials, false
      default_config :extra_parameters, {}
      default_config :private_key_path do
        %w{id_rsa id_dsa}.map do |key|
          file = File.expand_path("~/.ssh/#{key}")
          file if File.exist?(file)
        end.compact.first
      end
      default_config :use_dns, false
      default_config :dns_suffix, nil

      deprecate_config_for :tenant, Util.outdent!("
        In vRA 8.x, the 'tenant' configuration is no longer relevant for authentication.
        Please use the 'domain' configuration in its place.".dup)

      # @return [String] the driver's display name in `kitchen list`
      def name
        "vRA"
      end

      # Resolves the vRA username and password, prompting if necessary.
      #
      # Sources are tried in order: explicit config, then the +VRA_USER_NAME+
      # and +VRA_USER_PASSWORD+ environment variables, then the credential
      # cache, then an interactive prompt.
      #
      # @param force_change [Boolean] prompt even if credentials already
      #   resolved, used to re-ask after an authentication failure
      # @return [void]
      def check_config(force_change = false)
        config[:username] = config[:username] || ENV["VRA_USER_NAME"]
        config[:password] = config[:password] || ENV["VRA_USER_PASSWORD"]
        c_load if config[:username].nil? && config[:password].nil?

        config[:username] = ask("Enter Username: e.g. johnsmith") if config[:username].nil? || force_change
        config[:password] = ask("Enter password: ") { |q| q.echo = "*" } if config[:password].nil? || force_change
        c_save if config[:cache_credentials]
      end

      # Writes the resolved credentials to +.kitchen/cached_vra+.
      #
      # @note This does not currently work. The cipher is constructed as
      #   +OpenSSL::Cipher.new("cip-her-aes")+, which is not a real algorithm
      #   name, so this raises immediately and the bare +rescue+ turns it into
      #   an "Unable to save credentials" message. Setting +cache_credentials+
      #   therefore has no effect beyond printing that line.
      #
      # @return [void]
      def c_save
        cipher = OpenSSL::Cipher.new("cip-her-aes")
        cipher.encrypt
        cipher.key = Digest::SHA1.hexdigest(config[:base_url])
        iv_user = cipher.random_iv
        cipher.iv = iv_user
        username = cipher.update(config[:username]) + cipher.final
        iv_pwd = cipher.random_iv
        cipher.iv = iv_pwd
        password = cipher.update(config[:password]) + cipher.final
        output = "#{Base64.encode64(iv_user).strip!}:#{Base64.encode64(username).strip!}:#{Base64.encode64(iv_pwd).strip!}:#{Base64.encode64(password).strip!}"
        file = File.open(".kitchen/cached_vra", "w")
        file.write(output)
        file.close
      rescue
        puts "Unable to save credentials"
      end

      # Reads credentials back from +.kitchen/cached_vra+.
      #
      # @note Fails for the same reason as {#c_save} -- the cipher name is not
      #   valid -- so a cache is never successfully read. Since nothing ever
      #   writes the file either, this is normally a no-op.
      #
      # @return [void]
      def c_load
        if File.exist? ".kitchen/cached_vra"
          encrypted = File.read(".kitchen/cached_vra")
          iv_user = Base64.decode64(encrypted.split(":")[0] + '\n')
          username = Base64.decode64(encrypted.split(":")[1] + "\n")
          iv_pwd = Base64.decode64(encrypted.split(":")[2] + "\n")
          password = Base64.decode64(encrypted.split(":")[3] + "\n")
          cipher = OpenSSL::Cipher.new("cip-her-aes")
          cipher.decrypt
          cipher.key = Digest::SHA1.hexdigest(config[:base_url])
          cipher.iv = iv_user
          config[:username] = cipher.update(username) + cipher.final
          cipher.iv = iv_pwd
          config[:password] = cipher.update(password) + cipher.final
        end
      rescue
        puts "Failed to load cached credentials"
      end

      # Requests a deployment from vRA and waits until it can be logged into.
      #
      # Returns immediately if the state already names a deployment, so a
      # re-run does not build a second one.
      #
      # @param state [Hash] mutable instance state; gains +deployment_id+,
      #   +hostname+, and +ssh_key+
      # @return [void]
      # @raise [RuntimeError] if the vRA request fails or does not yield
      #   exactly one VM
      def create(state)
        return if state[:deployment_id]

        server = request_server
        state[:deployment_id] = server.deployment_id
        state[:hostname]    = hostname_for(server)
        state[:ssh_key]     = config[:private_key_path] unless config[:private_key_path].nil?

        wait_for_server(state, server)
        info("Server #{server.deployment_id} (#{server.name}) ready.")
      end

      # Works out the address Test Kitchen should connect to.
      #
      # With +use_dns+ set, the server's name is used, optionally suffixed with
      # +dns_suffix+. Otherwise the IP address is preferred, falling back to
      # the name with a warning when vRA reports no address.
      #
      # @param server [Vra::Resource] the VM vRA built
      # @return [String] a hostname or IP address
      # @raise [RuntimeError] if +use_dns+ is set but vRA returned no name
      def hostname_for(server)
        if config[:use_dns]
          raise "No server name returned for the vRA request" if server.name.nil?

          return config[:dns_suffix] ? "#{server.name}.#{config[:dns_suffix]}" : server.name
        end

        ip_address = server.ip_address
        if ip_address.nil?
          warn("Server #{server.deployment_id} has no IP address. Falling back to server name (#{server.name})...")
          server.name
        else
          ip_address
        end
      end

      # Submits the catalog request and waits for vRA to finish building it.
      #
      # @return [Vra::Resource] the single VM the blueprint produced
      # @raise [RuntimeError] if the request failed, or produced zero or more
      #   than one VM
      def request_server
        info("Building vRA catalog request...")

        deployment_request = catalog_request.submit

        info("Catalog request #{deployment_request.id} submitted.")
        if config[:unique_name]
          info("Deployment name is deployment_#{deployment_request.id}")
        end

        wait_for_request(deployment_request)
        raise "The vRA request failed: #{deployment_request.completion_details}" if deployment_request.failed?

        servers = deployment_request.resources.select(&:vm?)
        raise "The vRA request created more than one server. The catalog blueprint should only return one." if servers.size > 1
        raise "the vRA request did not create any servers." if servers.size == 0

        servers.first
      end

      # Waits for the transport to accept a connection, retrying on failure.
      #
      # Backs off in five-second steps up to thirty seconds between attempts.
      # Once +server_ready_retries+ is exceeded the deployment is destroyed
      # before the error is re-raised, so a machine that never comes up is not
      # left running and billable.
      #
      # @param state [Hash] instance state describing how to connect
      # @param server [Vra::Resource] the VM being waited on
      # @return [void]
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
            error("Retries exceeded. Destroying server...")
            destroy(state)
            raise
          else
            warn("Sleeping #{sleep_time} seconds and retrying...")
            sleep sleep_time
            retry
          end
        end
      end

      # Destroys the vRA deployment, if one exists.
      #
      # A deployment that vRA no longer knows about, or that offers no destroy
      # action, is treated as already gone rather than an error. The cached
      # credentials file is removed afterwards.
      #
      # @param state [Hash] instance state naming the deployment
      # @return [void]
      def destroy(state)
        return if state[:deployment_id].nil?

        begin
          server = vra_client.deployments.by_id(state[:deployment_id])
        rescue ::Vra::Exception::NotFound
          warn("No server found with ID #{state[:deployment_id]}, assuming it has been destroyed already.")
          return
        end

        begin
          destroy_request = server.destroy
        rescue ::Vra::Exception::NotFound
          info("Server not found, or no destroy action available, perhaps because it is already destroyed.")
          return
        end
        info("Destroy request #{destroy_request.id} submitted.")
        wait_for_request(destroy_request)
        info("Destroy request complete.")

        File.delete(".kitchen/cached_vra") if File.exist?(".kitchen/cached_vra")
        info("Removed cached file")
      end

      # Builds the vRA catalog request for the configured blueprint.
      #
      # When +catalog_name+ is given it is resolved to a catalog ID first.
      # A deployment name is only sent when +unique_name+ is false; otherwise
      # vRA is left to name the deployment after its request ID.
      #
      # @return [Vra::CatalogRequest] a request ready to submit
      # @raise [Kitchen::InstanceFailure] if no catalog could be resolved
      def catalog_request # rubocop:disable Metrics/MethodLength
        unless config[:catalog_name].nil?
          info("Fetching Catalog ID by Catalog Name")
          catalog_items = vra_client.catalog.fetch_catalog_items(config[:catalog_name])
          begin
            config[:catalog_id] = catalog_items[0].id
            info("Using Catalog with ID: #{catalog_items[0].id}")
          rescue
            error("Unable to retrieve Catalog ID from Catalog Name: #{config[:catalog_name]}")
          end
        end

        if config[:catalog_id].nil?
          raise Kitchen::InstanceFailure, "Unable to create deployment without a valid catalog"
        end

        deployment_params = {
          image_mapping: config[:image_mapping],
          flavor_mapping: config[:flavor_mapping],
          project_id: config[:project_id],
          version: config[:version],
        }.tap do |h|
          h[:name] = config[:deployment_name] unless config[:unique_name]
        end

        catalog_request = vra_client.catalog.request(config[:catalog_id], deployment_params)

        config[:extra_parameters].each do |key, value_data|
          catalog_request.set_parameters(key, value_data)
        end

        catalog_request
      end

      # The vRA API client, built from the resolved credentials.
      #
      # On any failure the credentials are re-prompted, on the assumption that
      # what failed was authentication.
      #
      # @return [Vra::Client]
      def vra_client
        check_config config[:cache_credentials]
        @client ||= ::Vra::Client.new(
          base_url:   config[:base_url],
          username:   config[:username],
          password:   config[:password],
          domain:     config[:domain],
          verify_ssl: config[:verify_ssl]
        )
      rescue => _e
        check_config true
      end

      # Polls a vRA request until it completes or times out.
      #
      # Polls every +request_refresh_rate+ seconds, logging each change of
      # status, and gives up after +request_timeout+ seconds.
      #
      # @param request [Vra::Request] the request to poll
      # @return [void]
      # @raise [Timeout::Error] if the request does not complete in time
      def wait_for_request(request)
        # config = check_config config

        last_status = ""
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
