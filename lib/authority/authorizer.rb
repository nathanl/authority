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
    Authority.adjectives.each do |adjective|
      def_delegator :"self.class", :"#{adjective}_by?"
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

  end

  class NoAuthorizerError < StandardError ; end
end
