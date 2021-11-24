# Change Log

## v1.4.0

* Add flag for `sticky_sessions` for apps that need it

## v1.3.0

* Add support for sending metrics to DataDog via `dogstatsd`

## v1.2.0

* Tune kernel according to Banyan best practices
* Support configurable rate limiting

## v1.1.14

* Add variables to support IMDS v2

## v1.1.13

* Add descriptions to each rule in the security group
* Add all resources to module output so you can reference them downstream
* Install pybanyan so it's available for troubleshooting and automation

## v1.1.12

* Support individual tags per resource.

## v1.1.11

* Documented the `host_tags`, `groups_by_userinfo`, and `name_prefix` input variables.

## v1.1.10

* Support additional AccessTier tags via `host_tags` input variable.
* Support large tokens via `groups_by_userinfo` input variable.
* Support custom naming prefix for all AWS resources via `name_prefix` input variable.

## v1.1.9

* Align release to correct tag

## v1.1.8

* Add custom tags to port 80 listener for NLB

## v1.1.7

* Better support for port 80 redirects

## v1.1.6

* Added parameter for setting an IAM Instance Profile on ASG instances.

## v1.1.5

* Republished in the Terraform Registry under banyansecurity org.

## v1.1.4

* Added instructions for upgrading to new versions of netagent.

## v1.1.0

* First production-ready release.
* Added option for HTTP-to-HTTPS redirect.

## v0.1.1

* Fix subnet variable names in README example (#4).
* Create new launch config before destroying the old one (#3).
* Add security group ID as output (#2).
* Support custom launch configs (#1).

## v0.1.0

* Initial commit.
