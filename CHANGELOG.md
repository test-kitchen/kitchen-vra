# Change Log

## Unreleased

* chore(deps): update actions/checkout action to v5 ([#74](https://github.com/test-kitchen/kitchen-vra/pull/74)) ([bc06b8c](https://github.com/test-kitchen/kitchen-vra/commit/bc06b8c))
* Fix typos ([#78](https://github.com/test-kitchen/kitchen-vra/pull/78)) ([298e742](https://github.com/test-kitchen/kitchen-vra/commit/298e742))
* Require Ruby 3.1+ and modernize CI ([#79](https://github.com/test-kitchen/kitchen-vra/pull/79)) ([d2df4d4](https://github.com/test-kitchen/kitchen-vra/commit/d2df4d4))
* Update actions/checkout action to v7 - autoclosed ([#77](https://github.com/test-kitchen/kitchen-vra/pull/77)) ([fae5260](https://github.com/test-kitchen/kitchen-vra/commit/fae5260))
* Update googleapis/release-please-action action to v5 - autoclosed ([#76](https://github.com/test-kitchen/kitchen-vra/pull/76)) ([fab5e69](https://github.com/test-kitchen/kitchen-vra/commit/fab5e69))
* Docs: rewrite README for new users and split contributor docs ([#80](https://github.com/test-kitchen/kitchen-vra/pull/80)) ([d9ebc45](https://github.com/test-kitchen/kitchen-vra/commit/d9ebc45))
* Standardize renovate config and remove dependabot ([#81](https://github.com/test-kitchen/kitchen-vra/pull/81)) ([be552bd](https://github.com/test-kitchen/kitchen-vra/commit/be552bd))

## [3.3.3](https://github.com/test-kitchen/kitchen-vra/compare/v3.3.2...v3.3.3) (2024-06-27)

### Bug Fixes

* release please configs ([#69](https://github.com/test-kitchen/kitchen-vra/issues/69)) ([fa27fb1](https://github.com/test-kitchen/kitchen-vra/commit/fa27fb16997917b6e04e2f63de1c3ac5bcc920a2))

### Other Changes

* Update ffi-yajl requirement from &gt;= 2.2.3, &lt; 2.5.0 to &gt;= 2.2.3, &lt; 3.1.0 ([#64](https://github.com/test-kitchen/kitchen-vra/pull/64)) ([1afb763](https://github.com/test-kitchen/kitchen-vra/commit/1afb763))
* Configure Renovate ([#67](https://github.com/test-kitchen/kitchen-vra/pull/67)) ([995a9eb](https://github.com/test-kitchen/kitchen-vra/commit/995a9eb))
* Updated the ruby version ([#68](https://github.com/test-kitchen/kitchen-vra/pull/68)) ([7ceca30](https://github.com/test-kitchen/kitchen-vra/commit/7ceca30))

## [3.3.2](https://github.com/chef-partners/kitchen-vra/tree/v3.3.2)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.3.1...v3.3.2)

- This change helps in getting unique name of a deployment. The new deployment name will be deployment_deploymentId. We need to pass **unique_name** as true(unique_name: true) in the driver configuration.

* Update rack requirement from &gt;= 1.6, &lt; 3.0 to &gt;= 1.6, &lt; 4.0 ([#56](https://github.com/test-kitchen/kitchen-vra/pull/56)) ([2913dcb](https://github.com/test-kitchen/kitchen-vra/commit/2913dcb))
* Unique name for the newly provisioned VMs. ([#66](https://github.com/test-kitchen/kitchen-vra/pull/66)) ([6ca4d6d](https://github.com/test-kitchen/kitchen-vra/commit/6ca4d6d))

## [3.3.1](https://github.com/chef-partners/kitchen-vra/tree/v3.3.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.3.0...v3.3.1)

- Fixed the issue with catalog lookup using catalog_name config [\#61](https://github.com/chef-partners/kitchen-vra/pull/61) ([ashiqueps](https://github.com/ashiqueps))

## [3.3.0](https://github.com/chef-partners/kitchen-vra/tree/v3.3.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.2.1...v3.3.0)

- Replaced the tenant attribute with the domain attribute [\#59](https://github.com/chef-partners/kitchen-vra/pull/59) ([ashiqueps](https://github.com/ashiqueps))

## [3.2.1](https://github.com/chef-partners/kitchen-vra/tree/v3.2.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.2.0...v3.2.1)

- Updated username example when prompt ask for username [\#57](https://github.com/chef-partners/kitchen-vra/pull/57) ([sanjain-progress](https://github.com/sanjain-progress))

## [3.2.0](https://github.com/chef-partners/kitchen-vra/tree/v3.2.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.1.0...v3.2.0)

- Support for Ruby 3.1
- Github workflow improvements

* include ruby 3.1 in ci ([#52](https://github.com/test-kitchen/kitchen-vra/pull/52)) ([0d863e2](https://github.com/test-kitchen/kitchen-vra/commit/0d863e2))
* add linters and publish action ([#53](https://github.com/test-kitchen/kitchen-vra/pull/53)) ([8cfed3b](https://github.com/test-kitchen/kitchen-vra/commit/8cfed3b))
* reuse existing workflow ([#54](https://github.com/test-kitchen/kitchen-vra/pull/54)) ([177946a](https://github.com/test-kitchen/kitchen-vra/commit/177946a))

## [3.1.0](https://github.com/chef-partners/kitchen-vra/tree/v3.1.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.0.1...v3.1.0)

- Move usage documentation from the readme to the kitchen.ci website
- Make the version configuration optional
- Remove the bundler dev dep
- Update the gemspec for the new maintainer of this project

* Target Ruby 2.7 in rubocop ([b25030d](https://github.com/test-kitchen/kitchen-vra/commit/b25030d))
* Update the owner and the repo in the gemspec ([14beda9](https://github.com/test-kitchen/kitchen-vra/commit/14beda9))
* make version parameter optional in kitchen yml ([#51](https://github.com/test-kitchen/kitchen-vra/pull/51)) ([72a1110](https://github.com/test-kitchen/kitchen-vra/commit/72a1110))

## [3.0.1](https://github.com/chef-partners/kitchen-vra/tree/v3.0.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v3.0.0...v3.0.1)

- Updated the rack gem dependency to allow for modern releases of rack.

* Update rack requirement from ~&gt; 1.6 to &gt;= 1.6, &lt; 3.0 ([#47](https://github.com/test-kitchen/kitchen-vra/pull/47)) ([aa357b9](https://github.com/test-kitchen/kitchen-vra/commit/aa357b9))

## [3.0.0](https://github.com/chef-partners/kitchen-vra/tree/v3.0.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.7.1...v3.0.0)

- kitchen-vra now supports VMware vRealize Automation 8. See the readme of kitchen.ci driver documentation for new configuration options necessary for use with vRA 8. If you need support for vRA 7 make sure to pin to an earlier release.

* Support VRA8 ([#41](https://github.com/test-kitchen/kitchen-vra/pull/41)) ([9c10283](https://github.com/test-kitchen/kitchen-vra/commit/9c10283))
* Require Ruby 2.7 and later ([#44](https://github.com/test-kitchen/kitchen-vra/pull/44)) ([933cae2](https://github.com/test-kitchen/kitchen-vra/commit/933cae2))
* Wire up dependabot and GitHub Actions ([#43](https://github.com/test-kitchen/kitchen-vra/pull/43)) ([84ad5d4](https://github.com/test-kitchen/kitchen-vra/commit/84ad5d4))
* Update rake requirement from ~&gt; 10.0 to ~&gt; 13.0 ([#46](https://github.com/test-kitchen/kitchen-vra/pull/46)) ([e1a6599](https://github.com/test-kitchen/kitchen-vra/commit/e1a6599))
* Update ffi-yajl requirement from ~&gt; 2.2.3 to &gt;= 2.2.3, &lt; 2.5.0 ([#49](https://github.com/test-kitchen/kitchen-vra/pull/49)) ([b39b1d3](https://github.com/test-kitchen/kitchen-vra/commit/b39b1d3))
* Migrate from RuboCop to Chefstyle ([#50](https://github.com/test-kitchen/kitchen-vra/pull/50)) ([6f517dd](https://github.com/test-kitchen/kitchen-vra/commit/6f517dd))
* Update webmock requirement from ~&gt; 1.21 to ~&gt; 3.14 ([#45](https://github.com/test-kitchen/kitchen-vra/pull/45)) ([616958a](https://github.com/test-kitchen/kitchen-vra/commit/616958a))

## [2.7.1](https://github.com/chef-partners/kitchen-vra/tree/v2.7.1)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.7.0...v2.7.1)

- Pin vmware-vra gem dep to < 3 to prevent pulling in the new release

* Updated the vmware-vra gem dependency ([#42](https://github.com/test-kitchen/kitchen-vra/pull/42)) ([f13906c](https://github.com/test-kitchen/kitchen-vra/commit/f13906c))

## [2.7.0](https://github.com/chef-partners/kitchen-vra/tree/v2.7.0)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.6.0...v2.7.0)

- Accept shirt size option available in blueprint as input in kitchen.yml

* Updates to resolve CVE. Fixes #31. ([#32](https://github.com/test-kitchen/kitchen-vra/pull/32)) ([05bda6c](https://github.com/test-kitchen/kitchen-vra/commit/05bda6c))
* Update README.md ([650df37](https://github.com/test-kitchen/kitchen-vra/commit/650df37))
* fix travis failures ([#38](https://github.com/test-kitchen/kitchen-vra/pull/38)) ([814e00a](https://github.com/test-kitchen/kitchen-vra/commit/814e00a))
* Enhanced kitchen driver to accept shirt size option in kitchen.yml. ([#37](https://github.com/test-kitchen/kitchen-vra/pull/37)) ([4da6ef5](https://github.com/test-kitchen/kitchen-vra/commit/4da6ef5))

## [2.6.0](https://github.com/test-kitchen/kitchen-vra/compare/v2.4.0...v2.6.0) (2018-03-01)

* Accept subtenant name as input in kitchen.yml ([#28](https://github.com/test-kitchen/kitchen-vra/pull/28)) ([92f7aea](https://github.com/test-kitchen/kitchen-vra/commit/92f7aea))
* v2.5.0 ([b47dd36](https://github.com/test-kitchen/kitchen-vra/commit/b47dd36))

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.4.0...v2.5.0)
**Closed issues:**
- Feature Query: Support for Capture Snapshot & Restore Snapshot [\#27](https://github.com/chef-partners/kitchen-vra/issues/27)
**Merged pull requests:**
- Accept subtenant name as input in kitchen.yml [\#28](https://github.com/chef-partners/kitchen-vra/pull/28) ([vinuphilip](https://github.com/vinuphilip))

## [2.4.0](https://github.com/chef-partners/kitchen-vra/tree/v2.4.0) (2018-01-22)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.3.0...v2.4.0)

**Merged pull requests:**

- Kitchen vRA enahancements [\#26](https://github.com/chef-partners/kitchen-vra/pull/26) ([rupeshpatel88](https://github.com/rupeshpatel88))

## [2.3.0](https://github.com/chef-partners/kitchen-vra/tree/v2.3.0) (2017-07-14)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.2.0...v2.3.0)

**Merged pull requests:**

- Switched to using set\_parameters [\#24](https://github.com/chef-partners/kitchen-vra/pull/24) ([lloydsmithjr03](https://github.com/lloydsmithjr03))
- Updates for travis and rubocop [\#23](https://github.com/chef-partners/kitchen-vra/pull/23) ([jjasghar](https://github.com/jjasghar))

* Added github templates ([bac40d6](https://github.com/test-kitchen/kitchen-vra/commit/bac40d6))
* 2.3.0 ([6efee6a](https://github.com/test-kitchen/kitchen-vra/commit/6efee6a))

## [2.2.0](https://github.com/chef-partners/kitchen-vra/tree/v2.2.0) (2017-02-15)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.1.0...v2.2.0)

**Merged pull requests:**

- Vra cache creds [\#16](https://github.com/chef-partners/kitchen-vra/pull/16) ([michaelschlies](https://github.com/michaelschlies))

* Updated the year in README ([1a0a15c](https://github.com/test-kitchen/kitchen-vra/commit/1a0a15c))

## [2.1.0](https://github.com/chef-partners/kitchen-vra/tree/v2.1.0) (2017-02-13)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Bump version for release [\#21](https://github.com/chef-partners/kitchen-vra/pull/21) ([jjasghar](https://github.com/jjasghar))
- Add support for a DNS suffix appended to server.name [\#19](https://github.com/chef-partners/kitchen-vra/pull/19) ([jeremymv2](https://github.com/jeremymv2))

* Added 2.1.0 changelog ([3546421](https://github.com/test-kitchen/kitchen-vra/commit/3546421))

## [2.0.0](https://github.com/chef-partners/kitchen-vra/tree/v2.0.0) (2016-12-15)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.3.0...v2.0.0)

**Merged pull requests:**

- replace 'servers.size ==0' with 'servers.empty?' [\#13](https://github.com/chef-partners/kitchen-vra/pull/13) ([adamleff](https://github.com/adamleff))
- fix travis notifications [\#11](https://github.com/chef-partners/kitchen-vra/pull/11) ([adamleff](https://github.com/adamleff))

* v2.0.0 ([75af468](https://github.com/test-kitchen/kitchen-vra/commit/75af468))
* merge conflict ([5b7b518](https://github.com/test-kitchen/kitchen-vra/commit/5b7b518))

## [1.3.0](https://github.com/chef-partners/kitchen-vra/tree/v1.3.0) (2016-01-25)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.2.0...v1.3.0)

**Merged pull requests:**

- Capping the retry delay when waiting for a server to 30 seconds [\#10](https://github.com/chef-partners/kitchen-vra/pull/10) ([adamleff](https://github.com/adamleff))

* adding to travis ([812c13a](https://github.com/test-kitchen/kitchen-vra/commit/812c13a))
* adding slack notifications to travis ([a9250ed](https://github.com/test-kitchen/kitchen-vra/commit/a9250ed))

## [1.2.0](https://github.com/chef-partners/kitchen-vra/tree/v1.2.0) (2015-11-26)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.1.0...v1.2.0)

**Merged pull requests:**

- Adding wait\_for\_server retry logic, and better failback for hostname. [\#7](https://github.com/chef-partners/kitchen-vra/pull/7) ([adamleff](https://github.com/adamleff))
- Update README.md [\#4](https://github.com/chef-partners/kitchen-vra/pull/4) ([trisharia](https://github.com/trisharia))

* Merge branch 'adamleff/dns-fallback' for PR #7 ([bd72f27](https://github.com/test-kitchen/kitchen-vra/commit/bd72f27))

## [1.1.0](https://github.com/chef-partners/kitchen-vra/tree/v1.1.0) (2015-10-13)

[Full Changelog](https://github.com/chef-partners/kitchen-vra/compare/v1.0.0...v1.1.0)

**Merged pull requests:**

- optional use\_dns [\#3](https://github.com/chef-partners/kitchen-vra/pull/3) ([stevehedrick](https://github.com/stevehedrick))

## [1.0.0](https://github.com/chef-partners/kitchen-vra/tree/v1.0.0) (2015-08-12)

**Merged pull requests:**

- Initial release, working in VMware HOL lab, tests passing [\#1](https://github.com/chef-partners/kitchen-vra/pull/1) ([adamleff](https://github.com/adamleff))


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*

* empty repo ([cabbb21](https://github.com/test-kitchen/kitchen-vra/commit/cabbb21))
