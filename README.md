# kitchen-vra

[![Gem Version](https://badge.fury.io/rb/kitchen-vra.svg)](https://badge.fury.io/rb/kitchen-vra)

A [Test Kitchen](https://kitchen.ci/) driver that provisions and destroys machines through [VMware vRealize Automation](https://www.vmware.com/products/vrealize-automation.html) (vRA, now Aria Automation), so you can test your cookbooks and infrastructure code against instances from your own vRA catalog.

Rather than talking to a hypervisor directly, this driver submits a catalog request to vRA and waits for the resulting deployment, so test instances follow the same blueprints, approvals, and policies as the rest of your estate.

> This documentation uses [Cinc Workstation](https://cinc.sh/) and the `cinc` commands throughout. Everything here works identically with Chef Workstation — see [Using with Chef](#using-with-chef).

## Requirements

- Ruby 3.1 or later (already satisfied if you use Cinc Workstation)
- Access to a vRA 8.x appliance
- A catalog item that provisions exactly **one** virtual machine — the driver rejects a request that returns more than one server
- Permission to request that catalog item, and to delete the resulting deployment

## Installation

This driver ships as part of [Cinc Workstation](https://cinc.sh/start/workstation/). If you have Cinc Workstation installed, there is nothing else to install.

To install it into a standalone Ruby:

```sh
gem install kitchen-vra
```

Or with Bundler, add it to your `Gemfile`:

```ruby
gem "kitchen-vra"
```

...then run `bundle install`.

## Authentication

Credentials are resolved in this order:

1. The `username` and `password` driver options
2. The `VRA_USER_NAME` and `VRA_USER_PASSWORD` environment variables
3. Cached credentials, if `cache_credentials` was enabled on a previous run
4. An interactive prompt

Keep credentials out of `kitchen.yml`. The usual approach is the environment:

```sh
export VRA_USER_NAME='myuser@corp.local'
export VRA_USER_PASSWORD='mypassword'
```

Setting `cache_credentials: true` stores the credentials after a successful run so later runs do not prompt. They are written to `.kitchen/cached_vra`, encrypted under a key derived from `base_url` and readable only by your user. Since `base_url` is not a secret, this hides the password from casual view rather than protecting it — treat the file as sensitive and avoid the option on shared machines.

## Quick Start

```yaml
---
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  verify_ssl: true

provisioner:
  name: cinc_infra

verifier:
  name: cinc_auditor

platforms:
  - name: ubuntu-22.04

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

Then run the full test cycle:

```sh
cinc kitchen test
```

Or step through it:

```sh
cinc kitchen create    # submit the catalog request and wait for the deployment
cinc kitchen converge  # apply your cookbook
cinc kitchen verify    # run your tests
cinc kitchen destroy   # destroy the vRA deployment
```

## Configuration

All options below are set under the `driver:` key in `kitchen.yml`.

### Required

| Option | Default | Description |
| --- | --- | --- |
| `base_url` | *none* | Base URL of the vRA appliance, e.g. `https://vra.corp.local`. Required. |
| `domain` | *none* | Authentication domain, e.g. `corp.local`. Required. |
| `project_id` | *none* | ID of the vRA project the deployment is created under. Required. |
| `image_mapping` | *none* | Name of the vRA image mapping to deploy, e.g. `Ubuntu 22.04`. Required. |
| `flavor_mapping` | *none* | Name of the vRA flavor mapping, which determines CPU and memory, e.g. `Small`. Required. |

You must also identify the catalog item with either `catalog_id` or `catalog_name`.

### Catalog item

| Option | Default | Description |
| --- | --- | --- |
| `catalog_id` | `nil` | ID of the catalog item to request. |
| `catalog_name` | `nil` | Name of the catalog item to request, resolved to an ID. Use instead of `catalog_id`. |
| `version` | `nil` | Version of the catalog item to request. Uses the latest if unset. |
| `extra_parameters` | `{}` | Additional catalog request parameters, keyed by parameter name. See [Extra parameters](#extra-parameters). |

### Credentials

| Option | Default | Description |
| --- | --- | --- |
| `username` | `$VRA_USER_NAME` | vRA username. Prompted for if not set anywhere. |
| `password` | `$VRA_USER_PASSWORD` | vRA password. Prompted for if not set anywhere. |
| `cache_credentials` | `false` | Cache credentials to disk after a successful run so later runs do not prompt. |
| `verify_ssl` | `true` | Verify the appliance's TLS certificate. Only disable against a lab with a self-signed certificate. |
| `tenant` | `nil` | **Deprecated.** Not used for authentication in vRA 8.x. Use `domain` instead. |

### Deployment

| Option | Default | Description |
| --- | --- | --- |
| `deployment_name` | the platform name | Name given to the vRA deployment. Ignored when `unique_name` is enabled. |
| `unique_name` | `false` | Name the deployment `deployment_<request id>` instead of using `deployment_name`, so concurrent runs do not collide. |

### Connectivity

| Option | Default | Description |
| --- | --- | --- |
| `use_dns` | `false` | Connect using the server's DNS name instead of its IP address. Needed when vRA does not report a reachable IP. |
| `dns_suffix` | `nil` | Suffix appended to the server name when `use_dns` is enabled, e.g. `corp.local`. |
| `private_key_path` | `~/.ssh/id_rsa` or `~/.ssh/id_dsa` | SSH private key used to connect. The first of those two files that exists is used. |

### Timing

| Option | Default | Description |
| --- | --- | --- |
| `request_timeout` | `600` | Seconds to wait for the catalog request to complete. |
| `request_refresh_rate` | `2` | Seconds between polls while waiting for the request. |
| `server_ready_retries` | `1` | Number of times to retry when the server is reported ready but is not yet reachable. Increase this on slow environments. |

## Extra parameters

`extra_parameters` passes additional inputs to the catalog request. Each entry is
keyed by the vRA parameter name, and gives the value along with its type:

```yaml
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  extra_parameters:
    environment:
      type: string
      value: test
    disk_size:
      type: integer
      value: 40
```

## Examples

### Selecting the catalog item by ID

```yaml
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_id: 9f4d4a7e-1234-4b8b-9c2f-77b6c9f0e111
  version: "2"
```

### Running several suites at once

Without `unique_name`, concurrent deployments share a name derived from the
platform, which is confusing in the vRA UI and can collide.

```yaml
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  unique_name: true
```

### Connecting by DNS name

```yaml
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  use_dns: true
  dns_suffix: corp.local
```

### A slow environment

```yaml
driver:
  name: vra
  base_url: https://vra.corp.local
  domain: corp.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  request_timeout: 1800
  request_refresh_rate: 10
  server_ready_retries: 5
```

### Lab appliance with a self-signed certificate

```yaml
driver:
  name: vra
  base_url: https://vra.lab.local
  domain: lab.local
  project_id: 6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c
  image_mapping: Ubuntu 22.04
  flavor_mapping: Small
  catalog_name: Ubuntu Server
  verify_ssl: false
```

## Troubleshooting

**"The vRA request created more than one server."** The driver requires a catalog
item that provisions exactly one VM. Point it at a single-machine blueprint.

**The request succeeds but Test Kitchen cannot connect.** vRA often reports a
deployment as ready slightly before the guest accepts connections. Raise
`server_ready_retries`. If vRA reports an unreachable IP, set `use_dns: true`
along with `dns_suffix`.

**Authentication fails on vRA 8.x.** Use `domain`, not `tenant`. The `tenant`
option is deprecated and is not used for authentication in 8.x.

## Using with Chef

This driver is not tied to Cinc. The examples above use Cinc Workstation and the `cinc_infra` provisioner, but the driver works exactly the same with [Chef Workstation](https://www.chef.io/downloads/tools/workstation) — run `kitchen` instead of `cinc kitchen`, and use `chef_infra` instead of `cinc_infra`:

```yaml
provisioner:
  name: chef_infra

verifier:
  name: inspec
```

No driver configuration changes are needed.

## Contributing

We'd love to hear from you if this doesn't work in your vRA environment. Bug reports and pull requests are welcome on [GitHub](https://github.com/test-kitchen/kitchen-vra). See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, how to run the tests, and the release process.

## License and Authors

Author: Chef Partner Engineering (<partnereng@chef.io>)

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
