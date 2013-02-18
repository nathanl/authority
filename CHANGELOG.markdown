# Changelog

Authority does its best to use [semantic versioning](http://semver.org).

## v2.4.2

Bugfix - make `authority_resource` inheritable. For instance, if you call `authorize_actions_for Llama` in one controller, a child controller does the same unless told otherwise.

## v2.4.1

The controller method name given to `authorize_actions_for` no longer has to be public. (We don't want to force controllers to make any method public that shouldn't be a routable action.)

## v2.4.0

Controller method `authorize_actions_for` can now be given a method name to dynamically determine the class to authorize. For example, `authorize_actions_for :model_class` will call the `model_class` method on the controller instance at request time.

## v2.3.2

- Updated `can?` to only pass options if it was given options.

## v2.3.1

- Had second thought and reworked `can?(:action)` to call `Application_authorizer.authorizes_to_#{action}?`. Ensured it's backwards compatible for the few people who started using this in the last day or so.

## v2.3.0

- Added generic `current_user.can?(:mimic_lemurs)` for cases where there is no resource to work with. This calls a corresponding class method on `ApplicationAuthorizer`, like `ApplicationAuthorizer.can_mimic_lemurs?`.
- Renamed `authority_action` to `authority_actions` (plural) to reflect the fact that you can set multiple actions at once. Use of the old method will raise a deprecation warning.
- Lots of test cleanup so that test output is clearer - run rspec with `--format doc --order default` to see it.

## v2.2.0

Allow passing options hash to `authorize_action_for`, like `authorize_action_for(@llama, :sporting => @hat_style)`.

## v2.1.0

Allow passing options hash, like `current_user.can_create?(Comment, :for => @post)`.

## v2.0.1

Documentation and test cleanup.

## v2.0.0

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
