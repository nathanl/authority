module ModelCitizen
  module Abilities
    extend ActiveSupport::Concern

    included do
      class_attribute :authorizer_name

      self.authorizer_name = "#{name}Authorizer"
    end

    module ClassMethods

      def creatable_by?(actor)
      end

      def readable_by?(actor)
      end

      def updatable_by?(actor)
      end

      def deletable_by?(actor)
      end

      def authorizer
        @authorizer ||= authorizer_name.constantize
      end
    end

    def creatable_by?(actor)
    end

    def readable_by?(actor)
    end

    def updatable_by?(actor)
    end

    def deletable_by?(actor)
    end

  end
end
