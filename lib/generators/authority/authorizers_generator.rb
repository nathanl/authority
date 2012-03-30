require 'rails/generators/base'

module Authority
  module Generators
    class AuthorizersGenerator < Rails::Generators::Base

      argument :parentClass, type: :string, default: 'Authority::Authorizer', banner: 'Parent class'
      desc "Generates one authorizer per model. Takes optional argument of parent class for authorizers." 

      def do_all
        confirm_authorizers
        make_authorizer_folder
        make_authorizers
      end

      # Non-public generator methods aren't automatically called
      private

      def confirm_authorizers
        message = <<-RUBY

        Preparing to populate #{authorizer_folder} with the following:
        #{authorizer_names.join(', ')}
        
        Each authorizer will subclass #{parentClass}. 
        RUBY
        message = message.strip_heredoc

        if parentClass == 'Authority::Authorizer'
          message.concat("(You can specify something else with `rails g authority:authorizers MyClass`)")
        end

        puts message.concat("\n\n")
      end

      def make_authorizer_folder
        # creates empty directory if none; doesn't empty the directory
        empty_directory authorizer_folder
      end

      def make_authorizers
        authorizer_names.each do |authorizer_name|
          filename = File.join(authorizer_folder, authorizer_name.underscore).concat('.rb')
          create_file filename do
            contents = <<-RUBY
              class #{authorizer_name} < #{parentClass} 
                # Define class and instance methods
              end
            RUBY
            contents.strip_heredoc
          end
        end
      end

      def authorizer_folder
        'app/authorizers'
      end

      def authorizer_names
        # TODO: Make Dir.glob recursive(**), in case there are model subdirs,
        # and create same structure in authorizers
        models_dir = File.join(Rails.root, 'app', 'models', '*.rb')
        Dir.glob(models_dir).map do |filepath| 
          filepath.split(/models./).last.gsub(/\.rb\z/, '').camelcase.concat('Authorizer')
        end
      end

    end
  end
end
