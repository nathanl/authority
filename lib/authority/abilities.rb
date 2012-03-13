module Authority
  module Abilities
    extend ActiveSupport::Concern

    included do
      class_attribute :authorizer_name

      self.authorizer_name = "#{name}Authorizer"
    end

    module ClassMethods

      Authority.adjectives.each do |adjective|

        # Metaprogram needed methods, allowing for nice backtraces
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{adjective}_by?(user)
            authorizer.#{adjective}_by?(user)
          end
        RUBY
      end

      def authorizer
        begin
          @authorizer ||= authorizer_name.constantize
        rescue StandardError => e
          if e.is_a?(NameError)
            raise Authority::NoAuthorizerError.new("#{authorizer_name} does not exist in your application")
          else
            raise e
          end
        end
      end
    end

      Authority.adjectives.each do |adjective|

        # Metaprogram needed methods, allowing for nice backtraces
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{adjective}_by?(user)
            authorizer.#{adjective}_by?(user)
          end

          def authorizer
            self.class.authorizer.new(self)
          end
        RUBY
      end

  end
end
