require 'rails/generators/base'

module Authority
  module Generators
    class AuthorizersGenerator < Rails::Generators::Base

      argument :parentClass, type: :string, default: 'Authority::Authorizer', banner: 'Parent class'

      def make_authorizer_folder
        # creates empty directory if none; doesn't empty the directory
        empty_directory authorizer_folder
      end

      desc "Generates one authorizer per model, with confirmation. Optionally, give name of parent class." 
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

      # Non-public generator methods aren't automatically called
      private

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
