module Authority
  class Authorizer
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

    # the instance default method calls the class default method
    def default(adjective, user, options = {})
      user_and_maybe_options = self.class.send(:user_and_maybe_options, user, options)
      self.class.send(:"#{adjective}_by?", *user_and_maybe_options)
    end

    # Each method simply calls the `default` method (instance or class)
    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{adjective}_by?(user, options = {})
          default(:#{adjective}, *user_and_maybe_options(user, options))
        end

        def #{adjective}_by?(user, options = {})
          user_and_maybe_options = self.class.send(:user_and_maybe_options, user, options)
          default(:#{adjective}, *user_and_maybe_options)
        end
      RUBY
    end

    def self.user_and_maybe_options(user, options = {})
      [user, options].tap {|args| args.pop if args.last == {}}
    end
    private_class_method :user_and_maybe_options
  end

  class NoAuthorizerError < StandardError ; end
end
