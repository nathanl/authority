# TODO

- Consider removing `config.security_violation_handler`, since `authority_forbidden` can already be redefined on any controller

## Tests

- Test with Rails 4
- Test `ActionController` integration
- Add tests for the generators

## Structural changes

- Consider the huge change from authorizer objects to modules for permissions. This eliminates the awkwardness of "to check a resource instance, let's go instantiate an authorizer and give it this resource instance..." If we make this change, describe a detailed upgrade path.
- Ensure that Authority can boot without the `configure` method having been run. Maybe this will mean having setters for `abilities` and `controller_action_map` that undefine and redefine those sets of methods if/when the user runs configuration.
