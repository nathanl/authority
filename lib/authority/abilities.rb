module Authority

  # Should be included into all models in a Rails app. Provides the model
  # with both class and instance methods like `updatable_by?(user)`
  # Exactly which methods get defined is determined from `config.abilities`;
  # the module is evaluated after any user-supplied config block is run
  # in order to make that possible.
  # All delegate to the methods of the same name on the model's authorizer.

  module Abilities
    extend ActiveSupport::Concern

    included do |base|
      class_attribute :authorizer_name

      # Set the default authorizer for this model.
      # - Look for an authorizer named like the model inside the model's namespace.
      # - If there is none, use 'ApplicationAuthorizer'
      self.authorizer_name = begin
        "#{base.name}Authorizer".constantize.name
      rescue NameError => e
        "ApplicationAuthorizer"
      end
    end


    def authorizer
      self.class.authorizer.new(self) # instantiate on every check, in case model has changed
    end

    module Definitions
      # Send all calls like `editable_by?` to an authorizer instance
      # Not using Forwardable because it makes it harder for users to track an ArgumentError
      # back to their authorizer
      Authority.adjectives.each do |adjective|
        define_method("#{adjective}_by?") { |*args| authorizer.send("#{adjective}_by?", *args) }
      end
    end
    include Definitions

    module ClassMethods
      include Definitions

      def authorizer=(authorizer_class)
        @authorizer          = authorizer_class
        self.authorizer_name = @authorizer.name
      end

      # @return [Class] of the designated authorizer
      def authorizer
        @authorizer ||= authorizer_name.constantize # Get an actual reference to the authorizer class
      rescue NameError
        raise Authority::NoAuthorizerError.new(
                  "#{authorizer_name} is set as the authorizer for #{self}, but the constant is missing"
              )
      end

    end

  end
end