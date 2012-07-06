# TODO

## Tests

- Add tests for the generators
- Test `ActionController` integration

## Documentation

## Features

Consider allowing an options hash for class-level checks. For example:

```ruby
link_to "Add Comment", new_comment_path if current_user.can_create?(Comment, :for => @post)
```

If we need to ask "can the user create a comment on this post?", this syntax would avoid having to instantiate a comment in order to check its associated post.
