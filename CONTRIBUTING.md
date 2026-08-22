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

Run the unit tests and the style check together:

```sh
bundle exec rake
```

Run them individually:

```sh
bundle exec rake test    # RSpec unit tests
bundle exec rake style   # Cookstyle / RuboCop
```

To run a single spec file:

```sh
bundle exec rspec spec/kitchen/driver/vra_spec.rb
```

Many style offenses can be corrected automatically:

```sh
bundle exec cookstyle -a
```

The unit tests stub the vRA client, so they do not contact an appliance and do
not require credentials.

### Manual testing against vRA

Changes that touch the catalog request or the deployment lifecycle should also be
exercised against a real appliance, since the stubbed tests cannot catch
API-level regressions. You will need a catalog item that provisions exactly one
VM, and permission to request and delete it.

Set `VRA_USER_NAME` and `VRA_USER_PASSWORD` rather than putting credentials in
`kitchen.yml`, and confirm in the vRA UI that `kitchen destroy` removed the
deployment — a run that fails partway through can leave one behind.

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
