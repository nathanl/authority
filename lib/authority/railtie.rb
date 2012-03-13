require 'rails'

module Authority
  class Railtie < ::Rails::Railtie

    initializer "authority.controller" do
      ActionController::Base.send(:include, Authority::Controller)
    end

  end
end

