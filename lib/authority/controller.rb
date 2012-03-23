module Authority
  module Controller

    # Gets included into the app's controllers automatically by the railtie

    extend ActiveSupport::Concern

    included do
      rescue_from Authority::SecurityViolation, :with => :authority_forbidden
      class_attribute :authority_resource
    end

    module ClassMethods

      # Sets up before_filter to ensure user is allowed to perform a given controller action
      #
      # @param [Class] model_class - class whose authorizer should be consulted
      # @param [Hash] options - can contain :actions to be merged with existing
      # ones and any other options applicable to a before_filter
      def authorize_actions_for(model_class, options = {})
        self.authority_resource = model_class
        authority_action(options[:actions] || {})
        before_filter :run_authorization_check, options
      end

      # Allows defining and overriding a controller's map of its actions to the model's authorizer methods
      #
      # @param [Hash] action_map - controller actions and methods, to be merged with existing action_map
      def authority_action(action_map)
        authority_action_map.merge!(action_map.symbolize_keys)
      end

      # The controller action to authority action map used for determining
      # which Rails actions map to which authority actions (ex: index to read)
      #
      # @return [Hash] A duplicated copy of the configured controller_action_map
      def authority_action_map
        @authority_action_map ||= Authority.configuration.controller_action_map.dup
      end
    end

    protected

    # Renders a static file to minimize the chances of further errors.
    #
    # @param [Exception] error, an error that indicates the user tried to perform a forbidden action. 
    def authority_forbidden(error)
      Authority.configuration.logger.warn(error.message)
      render :file => Rails.root.join('public', '403.html'), :status => 403, :layout => false
    end

    private

    # The before filter that will be setup to run when the class method
    # `authorize_actions_for` is called
    def run_authorization_check
      authorize_action_for self.class.authority_resource
    end

    # Convencience wrapper for sending configured user_method to extract the
    # request's current user
    #
    # @return [Object] the user object returned from sending the user_method
    def authority_user
      send(Authority.configuration.user_method)
    end

    # To be run in a before_filter; ensure this controller action is allowed for the user
    #
    # @param authority_resource [Class], the model class associated with this controller
    # @raise [MissingAction] if controller action isn't a key in `config.controller_action_map`
    def authorize_action_for(authority_resource)
      authority_action = self.class.authority_action_map[action_name.to_sym]
      if authority_action.nil?
        raise MissingAction.new("No authority action defined for #{action_name}")
      end
      Authority.enforce(authority_action, authority_resource, authority_user)
    end

    class MissingAction < StandardError ; end
  end
end
