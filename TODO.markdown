# TODO

## Design

- Carefully think through names of all public methods & see if they could be clearer or more intuitive

## Chores

- Add separate generator to make an empty authorizer for each file in `app/models` (prompt for each one)
- Test generators
- Have logging method call `to_s` if available; else inspect
- Configurable proc for logging method

## Documentation

- Make README more concise, or at least more navigable.
- How to bypass creating an authorizer for each model - by setting authorizer name directly and having them share.
- For instance-level checks, ensuring that you don't call `update` first; use `attributes=` before calling `authorize_action_on`.
- Example of checking clean/dirty attributes in instance-level checks. For example, if I'm only allowed to update blue laser cannons, can I make them red? Maybe I need to check whether the old value was blue?
- Examples of testing authorizers
  - Testing authorizer itself is more modular than testing same logic from the model
  - Models may share an authorizer; only test once
