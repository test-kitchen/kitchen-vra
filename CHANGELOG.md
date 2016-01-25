# kitchen-vra Changelog

## v1.3.0 (2016-01-25)
* [pr#10](https://github.com/chef-partners/kitchen-vra/pull/10) Capping the server wait_until_ready retry growth at 30 seconds.

## v1.2.0 (2015-11-25)
* [pr#7](https://github.com/chef-partners/kitchen-vra/pull/7) Added retry logic for wait_until_ready in cases where Test Kitchen would unwind (such as DNS issues). Added fallback logic for when a host has no IP address, complimenting the `use_dns` parameter.

## v1.1.0 (2015-10-13)
* New `use_dns` option (defaults to false) for the driver to use the server name instead of the IP address - thanks to @stevehedrick in PR [#3](https://github.com/chef-partners/kitchen-vra/pull/3)

## v1.1.0
* Initial reelase

