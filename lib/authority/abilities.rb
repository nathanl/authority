module Authority

  # Should be included into all models in a Rails app. Provides the model
  # with both class and instance methods like `updatable_by?(user)`
  # Exactly which methods get defined is determined from `config.abilities`;
  # the module is evaluated after any user-supplied config block is run
  # in order to make that possible.
  # All delegate to the methods of the same name on the model's authorizer.

  module Abilities
    extend ActiveSupport::Concern

    # Assume authorizer is `ApplicationAuthorizer` (but let the user change that)
    included do
      class_attribute :authorizer_name
      self.authorizer_name = "ApplicationAuthorizer"
    end

    module ClassMethods

      Authority.adjectives.each do |adjective|

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{adjective}_by?(user, options = {})
            if options.empty?
              authorizer.#{adjective}_by?(user)
            else
              authorizer.#{adjective}_by?(user, options)
            end
          end
        RUBY
      end

      # @return [Class] of the designated authorizer
      def authorizer
        @authorizer ||= authorizer_name.constantize # Get an actual reference to the authorizer class
      rescue NameError
        raise Authority::NoAuthorizerError.new("#{authorizer_name} does not exist in your application")
      end
    end

    Authority.adjectives.each do |adjective|

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{adjective}_by?(user, options = {})
          if options.empty?
            authorizer.#{adjective}_by?(user)
          else
            authorizer.#{adjective}_by?(user, options)
          end
        end

        def authorizer
          self.class.authorizer.new(self) # instantiate on every check, in case model has changed
        end
      RUBY
    end

  end
end
