# TODO

## Chores

- Add tests for the generators

## Documentation

- Example of checking clean/dirty attributes in instance-level checks. For example, if I'm only allowed to update blue laser cannons, can I make them red? Maybe I need to check whether the old value was blue?

## Features

- It would be nice to have an `authorized_link_to` method, which determines from the given path and the user's permissions whether to show the link. Not sure yet how hard this would be.
- **Breaking change**: Rework default strategies: instead of a single proc, have the configuration control the definition of `def self.default_strategy` on `Authority::Authorizer`. This will enable the user to override that method on any individual authorizer. So, for example, one could express "anyone can do anything with a widget" by defining `WidgetAuthorizer#default_strategy` to always return `true`, and "any admin can do anything with an admin-only resource, but nobody else can mess with them" by defining `AdminAuthorizer#default_strategy` to always return `user.is_admin?`.
