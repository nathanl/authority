module Authority
  class Authorizer
    extend Forwardable

    # The base Authorizer class, from which all the authorizers in an app will
    # descend. Provides the authorizer with both class and instance methods
    # like `updatable_by?(user)`.
    # Exactly which methods get defined is determined from `config.abilities`;
    # the class is evaluated after any user-supplied config block is run
    # in order to make that possible.

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    # Whitelisting approach: anything not specified will be forbidden
    def self.default(adjective, user, options = {})
      false
    end

    # Each instance method simply calls the corresponding class method
    Authority.adjective_methods.each do |adjective_method|
      def_delegator :"self.class", adjective_method
    end

    # Each class method simply calls the `default` method
    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{adjective}_by?(user, options = {})
          user_and_maybe_options = [user, options].tap {|args| args.pop if args.last == {}}
          default(:#{adjective}, *user_and_maybe_options)
        end
      RUBY
    end

    module Memoization
      extend ActiveSupport::Concern

      included do
        extend Memoist

        # Memoize each adjective instance method on this Authorizer
        Authority.adjective_methods.each do |adjective_method|
          memoize adjective_method, :identifier => name
        end
      end

      def flush_authority_cache
        methods_to_flush = Authority.adjective_methods.map do |adjective_method|
          :"#{self.class.name}_#{adjective_method}"
        end

        flush_cache *methods_to_flush
      end
    end

  end

  class NoAuthorizerError < StandardError ; end
end
