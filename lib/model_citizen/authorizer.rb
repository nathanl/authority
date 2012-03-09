module ModelCitizen
  class Authorizer

    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

  end
end
