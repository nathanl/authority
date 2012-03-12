module Authority
  class Configuration

    attr_accessor :default_strategy, :abilities

    def initialize
      @default_strategy = Proc.new { |able, authorizer, user|
        false
      }

      @abilities ||= {
        :create => 'creatable',
        :read   => 'readable',
        :update => 'updatable',
        :delete => 'deletable'
      }

      def @abilities.[]=(key, value)
        Authority.instance_variable_set(:@abilities, nil)
        super
      end
    end

  end
end
