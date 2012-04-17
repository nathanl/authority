module Authority
  class Configuration

    # Has default settings, overrideable in the initializer.

    attr_accessor :default_strategy, :abilities, :controller_action_map, :user_method, :security_violation_handler, :logger

    def initialize
      @default_strategy = Proc.new do |able, authorizer, user|
        false
      end
      

      @abilities = {
        :create => 'creatable',
        :read   => 'readable',
        :update => 'updatable',
        :delete => 'deletable'
      }

      @controller_action_map = {
        :index   => 'read',
        :show    => 'read',
        :new     => 'create',
        :create  => 'create',
        :edit    => 'update',
        :update  => 'update',
        :destroy => 'delete'
      }

      @user_method = :current_user

      @security_violation_handler = :authority_forbidden

      @logger = Logger.new(STDERR)
    end

  end
end
