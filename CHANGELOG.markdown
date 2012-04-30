# Changelog

This is mainly to document major new features and backwards-incompatible changes.

## Unreleased

- **Breaking change**: models now assume their authorizer is `ApplicationAuthorizer` unless told otherwise. Generator creates a blank `ApplicationAuthorizer`. This, combined with the change in v1.1.0, makes the `default_strategy` proc obsolete in favor of straightforward inheritance of a `default` method, so support for `config.default_strategy` is removed.
- Added accessors to `Authority::SecurityViolation` for user, action and resource, for use in custom security violation handlers.

## v1.1.0

- Added `Authority::Authorizer.default` class method which is called before the `default_strategy` proc and delegates to that proc. This can be overridden per authorizer.

## v1.0.0

- Added `config.security_violation_handler` so users can specify which controller method to use when rescuing `SecurityViolation`s
- Removed generator to make blank authorizers. On further consideration, one authorizer per model is counterproductive for most use cases, and I'd rather not encourage misuse.

## v1.0.0.pre4

Added generator to make blank authorizers. See `rails g authority:authorizers --help`.

## v1.0.0.pre3

- Rename controller methods (again):
  - `authorize_actions_on` => `authorize_actions_for`
  - `authorize_action_on` => `authorize_action_for`
- Cleaned up `authorize_action_for` to only accept a `resource` argument (the
  current user is determined by `authority_user`)

## v1.0.0.pre2

Rename controller methods:

- `check_authorization_on`  => `authorize_actions_on`
- `check_authorization_for` => `authorize_action_on`

## v1.0.0.pre1

- Renamed `config.authority_actions` to `config.controller_action_map`.

## v0.9.0

Initial release (basically)
