# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration

## Documentation

Document best suggestions from https://github.com/nathanl/authority/issues/9

## Features

### Allow options hash

Allow an options hash for class-level checks. For example:

```ruby
link_to "Add Comment", new_comment_path if current_user.can_create?(Comment, :for => @post)
```

If we need to ask "can the user create a comment on this post?", this syntax would avoid having to instantiate a comment in order to check its associated post.

This should be super-simple: just take the hash and pass it along. Users can specify `:for => @post` or `regarding: @bob` or whatever they want; it's up to them to use that in their authorizer method.

### Use translation files

- Move all user-facing messages into en.yml
- Add other languages
