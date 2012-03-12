module Authority
  module Controller
    extend ActiveSupport::Concern

    included do
      rescue_from Authority::SecurityTransgression, :with => 'forbidden'
      class_attribute :authority_resource
      class_attribute :authority_actions
    end

    module ClassMethods
      def check_authorization_on(model_class, options = {})
        self.authority_resource = model_class
        self.authority_actions  = Authority.configuration.authority_actions.merge(options[:actions] || {}).symbolize_keys
        before_filter :run_authorization_check, options
      end

      def authority_action(action_map)
        self.authority_actions.merge!(action_map).symbolize_keys
      end
    end

    protected

    def run_authorization_check
      check_authorization_for action_name, self.class.authority_resource, send(Authority.configuration.user_method)
    end

    def check_authorization_for(controller_action, authority_resource, user)
      authority_action = self.class.authority_actions[controller_action.to_sym]
      raise SecurityTransgression.new("") unless user.send("can_#{authority_action}?", authority_resource)
    end
  end
end
