require 'rails'

module Authority
  class Railtie < ::Rails::Railtie

    initializer "authority.controller" do
      # Include here instead of ApplicationController to avoid being lost when
      # classes are reloaded in Rails' development mode
      ActionController::Base.send(:include, Authority::Controller)
    end

  end
end
