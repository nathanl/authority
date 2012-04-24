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

    # Each instance method simply calls the corresponding class method
    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{adjective}_by?(user)
          self.class.#{adjective}_by?(user)
        end
      RUBY
    end

    # Each class method simply calls the user-definable default strategy
    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{adjective}_by?(user)
          default(:#{adjective}, user)
        end
      RUBY
    end

    def self.default(adjective, user)
      Authority.configuration.default_strategy.call(adjective, self, user)
    end

  end

  class NoAuthorizerError < StandardError ; end
end
