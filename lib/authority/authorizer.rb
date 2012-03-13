module Authority
  class Authorizer

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{adjective}_by?(user)
          Authority.configuration.default_strategy.call(:#{adjective}, self, user)
        end
      RUBY
    end

    Authority.adjectives.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{adjective}_by?(user)
          self.class.#{adjective}_by?(user)
        end
      RUBY
    end

  end

  class NoAuthorizerError < StandardError ; end ;
end
