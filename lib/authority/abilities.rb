module Authority

  # Should be included into all models in a Rails app. Provides the model
  # with both class and instance methods like `updatable_by?(user)`
  # Exactly which methods get defined is determined from `config.abilities`;
  # the module is evaluated after any user-supplied config block is run
  # in order to make that possible.
  # All delegate to the methods of the same name on the model's authorizer.

  module Abilities
    extend ActiveSupport::Concern
    extend Forwardable

    included do |base|
      class_attribute :authorizer_name

      # Set the default authorizer for this model
      # TODO: Look for an authorizer named like the model inside the model's
      # namespace. If there is none, use 'ApplicationAuthorizer' 
      self.authorizer_name = "ApplicationAuthorizer"
    end

    def authorizer
      self.class.authorizer.new(self) # instantiate on every check, in case model has changed
    end

    # Send all calls like `editable_by?` to an authorizer instance
    Authority.adjectives.each do |adjective|
      def_delegators :authorizer, :"#{adjective}_by?"
    end

    module ClassMethods
      extend Forwardable

      # Send all calls like `editable_by?` to the authorizer class
      Authority.adjectives.each do |adjective|
        def_delegators :authorizer, :"#{adjective}_by?"
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
