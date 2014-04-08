module Authority
  # Gets included into the app's controllers automatically by the railtie
  module Controller

    extend ActiveSupport::Concern
    include ActiveSupport::Rescuable unless defined?(Rails)

    def self.security_violation_callback
      Proc.new do |exception|
        # Through the magic of `instance_exec` `ActionController::Base#rescue_from`
        # can call this proc and make `self` the actual controller instance
        self.send(Authority.configuration.security_violation_handler, exception)
      end
    end

    included do
      rescue_from(Authority::SecurityViolation, :with => Authority::Controller.security_violation_callback)
      class_attribute :authority_resource, :instance_reader => false
    end

    attr_writer :authorization_performed

    def authorization_performed?
      !!@authorization_performed
    end

    def ensure_authorization_performed(options = {})
      return if authorization_performed?
      return if options[:if]     && !send(options[:if])
      return if options[:unless] && send(options[:unless])
      raise AuthorizationNotPerformed, "No authorization was performed for #{self.class.to_s}##{self.action_name}"
    end

    module ClassMethods

      # Sets up before_filter to ensure user is allowed to perform a given controller action
      #
      # @param [Class OR Symbol] resource_or_finder - class whose authorizer
      # should be consulted, or instance method on the controller which will
      # determine that class when the request is made
      # @param [Hash] options - can contain :actions to
      # be merged with existing
      # ones and any other options applicable to a before_filter
      def authorize_actions_for(resource_or_finder, options = {})
        self.authority_resource = resource_or_finder
        add_actions(options.fetch(:actions, {}))
        force_action(options[:all_actions]) if options[:all_actions]
        before_filter :run_authorization_check, options
      end

      # Allows defining and overriding a controller's map of its actions to the model's authorizer methods
      #
      # @param [Hash] action_map - controller actions and methods, to be merged with existing action_map
      def authority_actions(action_map)
        forced_action = action_map.delete(:all_actions)
        add_actions(action_map)
        force_action(forced_action) if forced_action
      end

      def authority_action(action_map)
        Authority.logger.warn "Authority's `authority_action` method has been renamed \
        to `authority_actions` (plural) to reflect the fact that you can \
        set multiple actions in one shot. Please update your controllers \
        accordingly. (called from #{caller.first})".squeeze(' ')
        authority_actions(action_map)
      end

      # Convenience wrapper for instance method
      def ensure_authorization_performed(options = {})
        after_filter(options.slice(:only, :except)) do |controller_instance|
          controller_instance.ensure_authorization_performed(options)
        end
      end

      # The controller action to authority action map used for determining
      # which Rails actions map to which authority actions (ex: index to read)
      #
      # @return [Hash] A duplicated copy of the configured controller_action_map
      def authority_action_map
        @authority_action_map ||= Authority.configuration.controller_action_map.dup
      end

      # Adds the passed in actions to the current action map.
      #
      # @param [Hash] action_map - controller actions and methods to be merged
      # with the existing action map
      def add_actions(action_map)
        authority_action_map.merge!(action_map)
      end

      # Updates the current action map to use the forced action for all of it's
      # actions.
      #
      # @param [String OR Symbol] forced_action - the authority action to use
      # for all Rails actions in the action map
      def force_action(forced_action)
        add_actions(
          Hash[authority_action_map.map {|key, _| [key, forced_action] }]
        )
      end
    end

    protected

    # To be run in a `before_filter`; ensure this controller action is allowed for the user
    # Can be used directly within a controller action as well, given an instance or class with or
    # without options to delegate to the authorizer.
    #
    # @param [Class] authority_resource, the model class associated with this controller
    # @param [Hash] options, arbitrary options hash to forward up the chain to the authorizer
    # @raise [MissingAction] if controller action isn't a key in `config.controller_action_map`
    def authorize_action_for(authority_resource, *options)
      # `action_name` comes from ActionController
      authority_action = self.class.authority_action_map[action_name.to_sym]
      if authority_action.nil?
        raise MissingAction.new("No authority action defined for #{action_name}")
      end

      Authority.enforce(authority_action, authority_resource, authority_user, *options)
      self.authorization_performed = true
    end

    # Renders a static file to minimize the chances of further errors.
    #
    # @param [Exception] error, an error that indicates the user tried to perform a forbidden action.
    def authority_forbidden(error)
      Authority.logger.warn(error.message)
      render :file => Rails.root.join('public', '403.html'), :status => 403, :layout => false
    end

    private

    # The `before_filter` that will be setup to run when the class method
    # `authorize_actions_for` is called
    def run_authorization_check
      authorize_action_for(*instance_authority_resource)
    end

    def instance_authority_resource
      return self.class.authority_resource       if self.class.authority_resource.is_a?(Class)
      send(self.class.authority_resource)
    rescue NoMethodError
      raise MissingResource.new(
          "Trying to authorize actions for '#{self.class.authority_resource}', but can't. \
          Must be either a resource class OR the name of a controller instance method that \
          returns one.".squeeze(' ')
      )
    end

    # Convenience wrapper for sending configured `user_method` to extract the
    # request's current user
    #
    # @return [Object] the user object returned from sending the user_method
    def authority_user
      send(Authority.configuration.user_method)
    end

    class MissingAction             < StandardError ; end
    class MissingResource           < StandardError ; end
    class AuthorizationNotPerformed < StandardError ; end
  end
end
