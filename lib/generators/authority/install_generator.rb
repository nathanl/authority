require 'rails/generators/base'

module Authority
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates an Authority initializer for your application." 

      def do_all
        copy_initializer
        copy_forbidden
        create_authorizers_directory
        message = <<-RUBY

        Install complete! See the README on Github for instructions on getting your
        app running with Authority.

        One note: each model needs to know the name of its its authorizer class. 
        You can specify that in the model like `authorizer_name FooAuthorizer`.
        If you don't, the `Article` model (for example) will look for `ArticleAuthorizer`.

        To generate one authorizer like that for each of your models, see
        `rails g authority:authorizers`. If you also want to specify your own
        parent class for them, use `rails g authority:authorizers MyClass`.

        RUBY
        puts message.strip_heredoc
        
      end

      private

      def copy_initializer
        template "authority_initializer.rb", "config/initializers/authority.rb"
      end

      def copy_forbidden
        template "403.html", "public/403.html"
      end

      def create_authorizers_directory
        # creates empty directory if none; doesn't empty the directory
        empty_directory "app/authorizers" 
      end

    end
  end
end
