require 'rails'

module Authority
  class Railtie < ::Rails::Railtie

    initializer "authority.controller" do
      # Include here instead of ApplicationController to avoid being lost when
      # classes are reloaded in Rails' development mode
      ActionController::Base.send(:include, Authority::Controller)
    end

    initializer "authority.memoization", :after => :load_config_initializers do
      if Authority.configuration.memoization
        config.after_initialize do
          Authority::Authorizer.descendants.each do |authorizer_klass|
            authorizer_klass.memoize_adjective_methods
          end
        end
      end
    end

  end
end
