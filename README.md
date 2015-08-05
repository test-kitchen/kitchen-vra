# kitchen-vra

A driver to allow Test Kitchen to consume vRealize Automation (vRA) resources to perform testing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kitchen-vra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen-vra

Or even better, install it via ChefDK:

    $ chef gem install kitchen-vra

## Usage

After installing the gem as described above, edit your .kitchen.yml file to set the driver to 'vra' and supply your login credentials:

```yaml
driver:
  name: vra
  username: myuser@corp.local
  password: mypassword
  tenant: mytenant
  base_url: https://vra.corp.local
  verify_ssl: true
```

Then configure your platforms.  A catalog_id is required for each platform:

```yaml
platforms:
  - name: centos6
    driver:
      catalog_id: e9db1084-d1c6-4c1f-8e3c-eb8f3dc574f9
  - name: centos7
    driver:
      catalog_id: c4211950-ab07-42b1-ba80-8f5d3f2c8251
```

Other options that you can set include:

 * **lease_days**: number of days to request for a lease, if your catalog item / blueprint requires it
 * **request_timeout**: amount of time, in seconds, to wait for a vRA request to complete.  Default is 600 seconds.
 * **cpus**: number of CPUs the host should have
 * **memory**: amount of RAM, in MB, the host should have
 * **requested_for**: the vRA login ID to list as the owner of this resource.  Defaults to the vRA username configured in the `driver` section.
 * **subtenant_id**: the Business Group ID to list as the owner.  This is required if the catalog item is a shared/global item; we are unable to determine the subtenant_id from the catalog, and vRA requires it to be set on every request.
 * **private_key_path**: path to the SSH private key to use when logging in.  Defaults to '~/.ssh/id_rsa' or '~/.ssh/id_dsa', preferring the RSA key.  Only applies to instances where SSH transport is used (i.e. does not apply to Windows hosts with the WinRM transport configured).

These settings can be set globally under the top-level `driver` section, or they can be set on each platform, which allows you to set globals and then override them.  For example, this configuration would set the CPU count to 1 except on the "large" platform:

```yaml
driver:
  name: vra
  cpus: 1

platforms:
  - name: small
    driver:
      catalog_id: 8a189191-fea6-43eb-981e-ee0fa40f8f57
  - name: large
    driver:
      catalog_id: 1d7c6122-18fa-4ed6-bd13-8a33b6c6ed50
      cpus: 2
```

## Contributing

We'd love to hear from you if this doesn't work in your vRA environment.  Please log a GitHub issue, or even better, submit a Pull Request with a fix!

1. Fork it ( https://github.com/chef-partners/kitchen-vra/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
