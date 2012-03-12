module Authority
  module Abilities
    extend ActiveSupport::Concern

    included do
      class_attribute :authorizer_name

      self.authorizer_name = "#{name}Authorizer"
    end

    module ClassMethods

      ADJECTIVES.each do |adjective|

        # Metaprogram needed methods, allowing for nice backtraces
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{adjective}_by?(actor)
            authorizer.#{adjective}_by?(actor)
          end
        RUBY
      end

      def authorizer
        @authorizer ||= authorizer_name.constantize
      end
    end

      ADJECTIVES.each do |adjective|

        # Metaprogram needed methods, allowing for nice backtraces
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{adjective}_by?(actor)
            self.class.authorizer.new(self).#{adjective}_by?(actor)
          end
        RUBY
      end

  end
end
