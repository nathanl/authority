# TODO

## Design

- Carefully think through names of all public methods & see if they could be clearer or more intuitive
- Consider making empty authorizers unnecessary: if one isn't defined, automatically define it as empty. This would reduce setup but slightly increase obfuscation of the workings.
- Decide whether there's any reason why `authorizer_action_on` needs a user argument, when we already know the method to call to get the current user.

## Chores

- Add separate generator to make an empty authorizer for each file in `app/models`
- Test generators
- Test view helpers
- Document how you can bypass creating an authorizer for each model - by setting authorizer name directly and having them share.
