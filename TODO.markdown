# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration
- Configure Rspec to run tests in random order and chase down any issues
- Switch to newer Rspec `expect()` syntax

## Structural changes

- Consider the huge change from authorizer objects to modules for permissions. This eliminates the awkwardness of "to check a resource instance, let's go instantiate an authorizer and give it this resource instance..." If we make this change, describe a detailed upgrade path.
- Ensure that Authority can boot without the `configure` method having been run.
