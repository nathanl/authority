# TODO

## Design
- Carefully think through names of all public methods & see if they could be clearer or more intuitive
- Consider making empty authorizers unnecessary: if one isn't defined, automatically define it as empty. This would reduce setup but slightly increase obfuscation of the workings.

## Chores

- Add separate generator to make an empty authorizer for each file in `app/models`
- Test generators
- Test view helpers
