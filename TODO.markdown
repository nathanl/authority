# TODO

## Design

- Carefully think through names of all public methods & see if they could be clearer or more intuitive

## Chores

- Add separate generator to make an empty authorizer for each file in `app/models`
  - Prompt for each one
  - Accept flag for parent class, like `rails g authority:authorizers --parent_class=MyApp::Authorizer`
- Test generators
- Configurable proc for logging method

## Documentation

- Example of checking clean/dirty attributes in instance-level checks. For example, if I'm only allowed to update blue laser cannons, can I make them red? Maybe I need to check whether the old value was blue?
- Examples of testing authorizers
  - Testing authorizer itself is more modular than testing same logic from the model
  - Models may share an authorizer; only test once
