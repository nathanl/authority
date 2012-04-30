# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration

## Documentation

- Example of checking clean/dirty attributes in instance-level checks. For example, if I'm only allowed to update blue laser cannons, can I make them red? Maybe I need to check whether the old value was blue?

## Features

- It would be nice to have an `authorized_link_to` method, which determines from the given path and the user's permissions whether to show the link. Not sure yet how hard this would be.
