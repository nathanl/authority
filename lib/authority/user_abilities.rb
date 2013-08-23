module Authority
  module UserAbilities
    extend ActiveSupport::Concern

    # Should be included into whatever class represents users in an app.
    # Provides methods like `can_update?(resource)`
    # Exactly which methods get defined is determined from `config.abilities`;
    # the module is evaluated after any user-supplied config block is run
    # in order to make that possible.
    # All delegate to corresponding methods on the resource.

    included do
      Authority.verbs.each do |verb|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def can_#{verb}?(resource, options = {})
            self_and_maybe_options = [self, options].tap {|args| args.pop if args.last == {}}
            resource.#{Authority.abilities[verb]}_by?(*self_and_maybe_options)
          end
        RUBY
      end

      include Memoization if Authority.use_memoization?
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

    module Memoization
      extend ActiveSupport::Concern

      included do
        extend Memoist

        # Memoize each verb instance method on this user
        Authority.verbs.each do |verb|
          memoize :"can_#{verb}?", :identifier => name
        end

        # Memoize the #can? instance method
        memoize :can?

        class_eval do
          # Flushes the authorizer memoization cache on this model
          def flush_authority_cache
            methods_to_flush = Authority.verbs.map {|verb| :"#{self.class.name}_can_#{verb}?" }
            methods_to_flush << :can?

            flush_cache *methods_to_flush
          end
        end
      end
    end

  end
end
