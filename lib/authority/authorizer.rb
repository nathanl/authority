module Authority
  class Authorizer

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    ADJECTIVES.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{adjective}_by?(actor)
          false
        end
      RUBY
    end

    ADJECTIVES.each do |adjective|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{adjective}_by?(actor)
          false
        end
      RUBY
    end

  end
end
