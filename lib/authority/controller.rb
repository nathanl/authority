module Authority
  module Controller
    extend ActiveSupport::Concern

    included do
      rescue_from Authority::SecurityTransgression, :with => :authority_forbidden
      class_attribute :authority_resource
      class_attribute :authority_actions
    end

    module ClassMethods

      # @param [Class] model_class - class whose authorizer should be consulted
      # @param [Hash] options - can contain :actions to be merged with existing
      # ones and any other options applicable to a before_filter
      def check_authorization_on(model_class, options = {})
        self.authority_resource = model_class
        self.authority_actions  = Authority.configuration.authority_actions.merge(options[:actions] || {}).symbolize_keys
        before_filter :run_authorization_check, options
      end

      # @param [Hash] action_map - controller actions and methods, to be merged with existing action_map
      def authority_action(action_map)
        self.authority_actions.merge!(action_map).symbolize_keys
      end
    end

    protected

    def authority_forbidden(error)
      Authority.configuration.logger.warn(error.message)
      render :file => Rails.root.join('public', '403.html'), :status => 403, :layout => false
    end

    def run_authorization_check
      check_authorization_for self.class.authority_resource, send(Authority.configuration.user_method)
    end

    def check_authorization_for(authority_resource, user)
      authority_action = self.class.authority_actions[action_name.to_sym]
      if authority_action.nil?
        raise MissingAction.new("No authority action defined for #{action_name}")
      end
      Authority.enforce(authority_action, authority_resource, user)
    end

    class MissingAction < StandardError ; end
  end
end
