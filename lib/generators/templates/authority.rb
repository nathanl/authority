Authority.configure do |config|

  # USER_METHOD
  # ===========
  # Authority needs the name of a method, available in any controller, which
  # will return the currently logged-in user.
  #
  # Default is:
  #
  # config.user_method = :current_user

  # DEFAULT_STRATEGY
  # ================
  # When no class-level method is defined on an Authorizer, a default_strategy
  # proc will be called to determine what to do.
  # Depending on your app, you may be able to put all the logic you need here.
  #
  # The arguments passed to this proc will be:
  #
  # able       - symbol name of class method being called on the Authorizer. 
  #              Ex: `:deletable_by?` or `:updatable_by?`
  # authorizer - constant name of authorizer. Ex: `WidgetAuthorizer` or `UserAuthorizer`
  # user       - user object (whatever that is in your application; found using config.user_method)
  #
  # For example:
  #
  # config.default_strategy = Proc.new { |able, authorizer, user|
  #   # Does the user have any roles which give this permission?
  #   (Permissions.find_by_name_and_authorizer(able, authorizer).roles & user.roles).any?
  # }
  #
  # OR
  #
  # config.default_strategy = Proc.new { |able, authorizer, user|
  #   able != 'implodable_by?' && user.has_hairstyle?('pompadour')
  # }
  #
  # Default strategy simply returns false, as follows:
  #
  # config.default_strategy =  Proc.new { |able, authorizer, user| false }
  
  # AUTHORITY_ACTIONS
  # For a given controller method, what verb must a user be able to do?
  # For example, a user can access 'show' if they 'can_read' the resource.
  #
  # Defaults are as follows:
  #
  # config.authority_actions = {
  #   :index   => 'read',
  #   :show    => 'read',
  #   :new     => 'create',
  #   :create  => 'create',
  #   :edit    => 'update',
  #   :update  => 'update',
  #   :destroy => 'delete'
  # }

  # ABILITIES
  # Teach Authority how to understand the verbs and adjectives in your system. Perhaps you
  # need {:microwave => 'microwavable'}. I'm not saying you do, of course. Stop looking at 
  # me like that.
  #
  # Defaults are as follows:
  #
  # config.abilities =  {
  #   :create => 'creatable',
  #   :read   => 'readable',
  #   :update => 'updatable',
  #   :delete => 'deletable'
  # }
  
  # LOGGER
  # If a user tries to perform an unauthorized action, where should we log that fact?
  # Provide a logger object which responds to `.warn(message)`
  #
  # Default is:
  #
  # config.logger = Logger.new(STDERR)
  #
  # Suggested setting for a Rails app is:
  config.logger = Rails.logger

end

