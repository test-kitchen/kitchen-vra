# Contributing to kitchen-vra

We'd love to hear from you if this driver doesn't work in your vRA environment. Bug reports, feature requests, and pull requests are all welcome.

## Reporting issues

Report bugs and request features on the [issue tracker](https://github.com/test-kitchen/kitchen-vra/issues). For bugs, please include:

- the version of kitchen-vra and Test Kitchen you are using
- your vRA version
- your `kitchen.yml` with credentials and internal hostnames removed
- the output of the failing command, ideally with `-l debug`

## Development setup

Clone the repository and install the dependencies:

```sh
git clone https://github.com/test-kitchen/kitchen-vra.git
cd kitchen-vra
bundle install
```

## Running the tests

Run everything CI runs -- style, unit tests and integration tests:

```sh
bundle exec rake
```

Or individually:

```sh
bundle exec rake test         # unit and integration specs
bundle exec rake unit         # unit specs only
bundle exec rake integration  # integration specs only
bundle exec rake style        # Cookstyle / Chefstyle
```

To run a single spec file, or a single example:

```sh
bundle exec rspec spec/vra_spec.rb
bundle exec rspec spec/vra_spec.rb:42
```

Many style offenses can be corrected automatically. Always pass `--chefstyle`:
a bare `cookstyle` run applies the cookbook cops as well and reports a hundred
offenses that do not apply to a gem.

```sh
bundle exec cookstyle --chefstyle -a
```

### Unit tests

`spec/vra_spec.rb` builds the driver directly and stubs the vmware-vra gem, so
the unit tests are fast and need neither an appliance nor credentials. Stubs
are verifying doubles checked against the real vmware-vra classes, so a rename
in that gem fails the suite rather than passing against a method that no longer
exists.

### Integration tests

`spec/integration` drives the driver the way `kitchen` drives it: a real
`kitchen.yml` read by the real loader, the driver Test Kitchen resolves from
`name: vra`, and `create`, `status` and `destroy` run against a vRA stubbed at
the wire with WebMock.

That covers the plugin lookup, the config merging Test Kitchen does before the
driver sees a value, `required_config` validation, the lazy defaults that need
an instance to resolve, and every line of vmware-vra that turns a catalog
request into HTTP and an HTTP response back into a `Resource` -- none of which
the unit tests reach.

A vRA appliance cannot be stood up in CI, but everything on this side of the
socket can be, so these run on every supported Ruby alongside the unit tests.

### Manual testing against vRA

Changes that touch the catalog request or the deployment lifecycle should also
be tried against a real appliance, since a stub can only ever answer the way it
was told to. You will need a catalog item that provisions exactly one VM, and
permission to request and delete it.

The `kitchen.yml` in the root of the repository is set up for exactly this. It
takes everything from the environment, so no site details or credentials end up
in the repository:

```sh
export VRA_BASE_URL='https://vra.corp.local'
export VRA_DOMAIN='corp.local'
export VRA_PROJECT_ID='6ba69375-2d1e-4a5e-9e9b-1a1a3f0e6d4c'
export VRA_CATALOG_NAME='Ubuntu Server'
export VRA_IMAGE_MAPPING='Ubuntu 22.04'
export VRA_FLAVOR_MAPPING='Small'
export VRA_USER_NAME='myuser@corp.local'
export VRA_USER_PASSWORD='mypassword'

bundle exec kitchen test
```

The suite verifies over the transport, so a green run means the deployment came
up and Test Kitchen could log in to it. Afterwards, confirm in the vRA UI that
`kitchen destroy` really removed the deployment -- a run that fails partway
through can leave one behind.

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster. Update the documentation in `README.md` when you add or change a
configuration option.

## Release process

Releases are handled by the maintainers.

1. Update `lib/kitchen/driver/vra_version.rb` with the new version.
2. Update `CHANGELOG.md`.
3. Merge to `main`; the [publish workflow](.github/workflows/publish.yml) builds
   the gem and pushes it to RubyGems.
