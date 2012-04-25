# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration

## Documentation

- Example of checking clean/dirty attributes in instance-level checks. For example, if I'm only allowed to update blue laser cannons, can I make them red? Maybe I need to check whether the old value was blue?

## Features

- It would be nice to have an `authorized_link_to` method, which determines from the given path and the user's permissions whether to show the link. Not sure yet how hard this would be.
- **Breaking change**: on installation, generate empty `ApplicationAuthorizer < Authority::Authorizer`. Any model which doesn't specify its authorizer would assume `ApplicationAuthorizer` instead of `[Modelname]Authorizer`; this way, users start out with a centralized authorizer scheme instead of with the assumption that every model needs its own. This also fits the pattern of Rails controllers.
