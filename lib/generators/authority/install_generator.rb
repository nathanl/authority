require 'rails/generators/base'

module Authority
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates an Authority initializer for your application."

      def do_all
        create_authorizers_directory
        copy_application_authorizer
        copy_initializer
        copy_forbidden
        message = <<-RUBY

        Install complete! See the README on Github for instructions on getting your
        app running with Authority.

        RUBY
        puts message.strip_heredoc

      end

      private

      def create_authorizers_directory
        # Creates empty directory if none; doesn't empty the directory
        empty_directory "app/authorizers"
      end

      def copy_application_authorizer
        template "application_authorizer.rb", "app/authorizers/application_authorizer.rb"
      end

      def copy_initializer
        template "authority_initializer.rb", "config/initializers/authority.rb"
      end

      def copy_forbidden
        template "403.html", "public/403.html"
      end

    end
  end
end
