# TODO

## Tests

- Test with Rails 4 and Ruby 2.0
- Test `ActionController` integration
- Add tests for the generators

## Code

- Look into using the `Forwardable` module for delegation in various places. (Does it handle passing options if given and nothing if not?)
- Have `.can?` accept and pass options
- Consider having `can?(:eat_cake)` call `ApplicationAuthorizer.authorizes_to_eat_cake?`. Maintain backwards compatibility but give a warning.

## Structural changes

- Consider the huge change from authorizer objects to modules for permissions. This eliminates the awkwardness of "to check a resource instance, let's go instantiate an authorizer and give it this resource instance..." If we make this change, describe a detailed upgrade path.
- Ensure that Authority can boot without the `configure` method having been run. Maybe this will mean having setters for `abilities` and `controller_action_map` that undefine and redefine those sets of methods if/when the user runs configuration.
