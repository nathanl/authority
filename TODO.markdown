# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration

## Features

## Add .can? method

- For non-resource-specific authorization, add `user.can?`. This should go to a corresponding authorizer method, which should call a method by the given name. For example, `user.can?(:access_admin_page)` goes to `ApplicationAuthorizer.allows_access_to?(:admin_page)` which calls `self.access_admin_page`. Or something.

### Use translation files

- Move all user-facing messages into en.yml
- Add other languages

## Structural changes

- Consider the huge change from authorizer objects to modules for permissions. This eliminates the awkwardness of "to check a resource instance, let's go instantiate an authorizer and give it this resource instance..." If we make this change, describe a detailed upgrade path.
- Ensure that Authority can boot without the `configure` method having been run.
