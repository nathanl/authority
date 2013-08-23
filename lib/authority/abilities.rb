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
      include Memoization if Authority.use_memoization?
      
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
      Authority.adjective_methods.each do |adjective_method|
        define_method(adjective_method) { |*args| authorizer.send(adjective_method, *args) }
      end
    end
    include Definitions

    module Memoization
      extend ActiveSupport::Concern

      included do
        extend Memoist
        # Memoize the authorizer instance on this model
        memoize :authorizer, :identifier => name

        # Memoize each adjective instance method
        Authority.adjective_methods.each do |adjective_method|
          memoize adjective_method, :identifier => name
        end

        class_eval do
          # Flushes the authorizer memoization cache on this model
          def flush_authority_cache
            methods_to_flush = Authority.adjective_methods.map do |adjective_method|
              :"#{self.class.name}_#{adjective_method}"
            end

            methods_to_flush << :"#{self.class.name}_authorizer"

            flush_cache *methods_to_flush
          end
        end
      end
    end

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