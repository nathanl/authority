# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration
- Work on readability of spec output when using `--format doc --order default` (pick up in `controller_spec`)

## Structural changes

- Consider the huge change from authorizer objects to modules for permissions. This eliminates the awkwardness of "to check a resource instance, let's go instantiate an authorizer and give it this resource instance..." If we make this change, describe a detailed upgrade path.
- Ensure that Authority can boot without the `configure` method having been run. Maybe this will mean having setters for `abilities` and `controller_action_map` that undefine and redefine those sets of methods if/when the user runs configuration.
