module Authority
  module UserAbilities

    # Should be included into whatever class represents users in an app.
    # Provides methods like `can_update?(resource)`
    # Exactly which methods get defined is determined from `config.abilities`;
    # the module is evaluated after any user-supplied config block is run
    # in order to make that possible.
    # All delegate to corresponding methods on the resource.

    Authority.verbs.each do |verb|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def can_#{verb}?(resource, options = {})
          self_and_maybe_options = [self, options].tap {|args| args.pop if args.last == {}}
          resource.#{Authority.abilities[verb]}_by?(*self_and_maybe_options)
        end
      RUBY
    end

    def can?(action, options = {})
      self_and_maybe_options = [self, options].tap {|args| args.pop if args.last == {}}
      begin
        ApplicationAuthorizer.send("authorizes_to_#{action}?", *self_and_maybe_options)
      rescue NoMethodError => original_exception
        begin
          # For backwards compatibility
          response = ApplicationAuthorizer.send("can_#{action}?", *self_and_maybe_options)
          Authority.logger.warn(
            "DEPRECATION WARNING: Please rename `ApplicationAuthorizer.can_#{action}?` to `authorizes_to_#{action}?`"
          )
          response
        rescue NoMethodError => new_exception
          raise original_exception
        end
      end
    end

  end
end
