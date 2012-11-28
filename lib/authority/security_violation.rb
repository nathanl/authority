module Authority
  class SecurityViolation < StandardError
    attr_reader :user, :action, :resource

    def initialize(user, action, resource)
      @user     = user
      @action   = action
      @resource = resource
    end

    def message
      "#{@user} is not authorized to #{@action} this resource: #{@resource}"
    end
  end
end
