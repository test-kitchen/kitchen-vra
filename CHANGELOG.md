# Change Log

## [v3.1.0](https://github.com/chef-partners/kitchen-vra/tree/v3.1.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.0.1...v3.1.0)

- Move usage documentation from the readme to the kitchen.ci website
- Make the version configuration optional
- Remove the bundler dev dep
- Update the gemspec for the new maintainer of this project

## [v3.0.1](https://github.com/chef-partners/kitchen-vra/tree/v3.0.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.0.0...v3.0.1)

- Updated the rack gem dependency to allow for modern releases of rack.

## [v3.0.0](https://github.com/chef-partners/kitchen-vra/tree/v3.0.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.7.1...v3.0.0)

- kitchen-vra now supports VMware vRealize Automation 8. See the readme of kitchen.ci driver documentation for new configuration options necessary for use with vRA 8. If you need support for vRA 7 make sure to pin to an earlier release.

## [v2.7.1](https://github.com/chef-partners/kitchen-vra/tree/v2.7.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.7.0...v2.7.1)

- Pin vmware-vra gem dep to < 3 to prevent pulling in the new release

## [v2.7.0](https://github.com/chef-partners/kitchen-vra/tree/v2.7.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.6.0...v2.7.0)

- Accept shirt size option available in blueprint as input in kitchen.yml 

## [v2.5.0](https://github.com/chef-partners/kitchen-vra/tree/v2.5.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.4.0...v2.5.0)

**Closed issues:**

- Feature Query: Support for Capture Snapshot & Restore Snapshot [\#27](https://github.com/chef-partners/kitchen-vra/issues/27)

**Merged pull requests:**

- Accept subtenant name as input in kitchen.yml [\#28](https://github.com/chef-partners/kitchen-vra/pull/28) ([vinuphilip](https://github.com/vinuphilip))

## [v2.4.0](https://github.com/chef-partners/kitchen-vra/tree/v2.4.0) (2018-01-22)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.3.0...v2.4.0)

**Merged pull requests:**

- Kitchen vRA enahancements [\#26](https://github.com/chef-partners/kitchen-vra/pull/26) ([rupeshpatel88](https://github.com/rupeshpatel88))

## [v2.3.0](https://github.com/chef-partners/kitchen-vra/tree/v2.3.0) (2017-07-14)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.2.0...v2.3.0)

**Merged pull requests:**

- Switched to using set\_parameters [\#24](https://github.com/chef-partners/kitchen-vra/pull/24) ([lloydsmithjr03](https://github.com/lloydsmithjr03))
- Updates for travis and rubocop [\#23](https://github.com/chef-partners/kitchen-vra/pull/23) ([jjasghar](https://github.com/jjasghar))

## [v2.2.0](https://github.com/chef-partners/kitchen-vra/tree/v2.2.0) (2017-02-15)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.1.0...v2.2.0)

**Merged pull requests:**

- Vra cache creds [\#16](https://github.com/chef-partners/kitchen-vra/pull/16) ([michaelschlies](https://github.com/michaelschlies))

## [v2.1.0](https://github.com/chef-partners/kitchen-vra/tree/v2.1.0) (2017-02-13)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.0.0...v2.1.0)

**Closed issues:**

- extra\_parameters  not passing correctly for vRA version  7.X [\#20](https://github.com/chef-partners/kitchen-vra/issues/20)
- Failure on notes config setting [\#15](https://github.com/chef-partners/kitchen-vra/issues/15)

**Merged pull requests:**

- Bump version for release [\#21](https://github.com/chef-partners/kitchen-vra/pull/21) ([jjasghar](https://github.com/jjasghar))
- Add support for a DNS suffix appended to server.name [\#19](https://github.com/chef-partners/kitchen-vra/pull/19) ([jeremymv2](https://github.com/jeremymv2))

## [v2.0.0](https://github.com/chef-partners/kitchen-vra/tree/v2.0.0) (2016-12-15)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.3.0...v2.0.0)

**Closed issues:**

- How do I specify windows and linux credentials for host vms? [\#14](https://github.com/chef-partners/kitchen-vra/issues/14)

**Merged pull requests:**

- replace 'servers.size ==0' with 'servers.empty?' [\#13](https://github.com/chef-partners/kitchen-vra/pull/13) ([adamleff](https://github.com/adamleff))
- fix travis notifications [\#11](https://github.com/chef-partners/kitchen-vra/pull/11) ([adamleff](https://github.com/adamleff))

## [v1.3.0](https://github.com/chef-partners/kitchen-vra/tree/v1.3.0) (2016-01-25)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.2.0...v1.3.0)

**Closed issues:**

- separate vra / machine credentials [\#9](https://github.com/chef-partners/kitchen-vra/issues/9)
- server\_ready\_retries timeout growth is awkward for our use case [\#8](https://github.com/chef-partners/kitchen-vra/issues/8)

**Merged pull requests:**

- Capping the retry delay when waiting for a server to 30 seconds [\#10](https://github.com/chef-partners/kitchen-vra/pull/10) ([adamleff](https://github.com/adamleff))

## [v1.2.0](https://github.com/chef-partners/kitchen-vra/tree/v1.2.0) (2015-11-26)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.1.0...v1.2.0)

**Closed issues:**

- Failed to complete \#create action: \[the vRA request did not create any servers.\] [\#5](https://github.com/chef-partners/kitchen-vra/issues/5)

**Merged pull requests:**

- Adding wait\_for\_server retry logic, and better failback for hostname. [\#7](https://github.com/chef-partners/kitchen-vra/pull/7) ([adamleff](https://github.com/adamleff))
- Update README.md [\#4](https://github.com/chef-partners/kitchen-vra/pull/4) ([trisharia](https://github.com/trisharia))

## [v1.1.0](https://github.com/chef-partners/kitchen-vra/tree/v1.1.0) (2015-10-13)
[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.0.0...v1.1.0)

**Closed issues:**

- vRA not managing IP addresses [\#2](https://github.com/chef-partners/kitchen-vra/issues/2)

**Merged pull requests:**

- optional use\_dns [\#3](https://github.com/chef-partners/kitchen-vra/pull/3) ([stevehedrick](https://github.com/stevehedrick))

## [v1.0.0](https://github.com/chef-partners/kitchen-vra/tree/v1.0.0) (2015-08-12)
**Merged pull requests:**

- Initial release, working in VMware HOL lab, tests passing [\#1](https://github.com/chef-partners/kitchen-vra/pull/1) ([adamleff](https://github.com/adamleff))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
