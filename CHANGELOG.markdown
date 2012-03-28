# Changelog

This is mainly to document major new features and backwards-incompatible changes.

## v1.0.0.pre4

Added generator to make blank authorizers. See `rails g authority::authorizers --help`.

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
