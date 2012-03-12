require 'rails'

module Authority
  class Railtie < ::Rails::Railtie

    initializer "authority.controller" do
      ApplicationController.send(:include, Authority::Controller)
    end

  end
end

