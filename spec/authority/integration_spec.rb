require 'spec_helper'
require 'support/example_model'
require 'support/user'

describe "integration from user through model to authorizer" do

  let(:user)           { User.new }
  let(:model_instance) { ExampleModel.new }

  describe "class methods" do

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "#{adjective_method}" do

        describe "if given an options hash" do

          it "delegates `#{adjective_method}` to its authorizer class, passing the options" do
            ExampleModel.authorizer.should_receive(adjective_method).with(user, :lacking => 'nothing')
            user.send(verb_method, ExampleModel, :lacking => 'nothing')
          end

        end

        describe "if not given an options hash" do

          it "delegates `#{adjective_method}` to its authorizer class, passing no options" do
            ExampleModel.authorizer.should_receive(adjective_method).with(user)
            user.send(verb_method, model_instance)
          end

        end

      end

    end

  end

  describe "instance methods" do

    let!(:authorizer_instance) { ExampleModel.authorizer.new(model_instance) }

    before :each do
      ExampleModel.authorizer.stub(:new).and_return(authorizer_instance)
    end

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "#{adjective_method}" do

        describe "if given an options hash" do

          it "delegates `#{adjective_method}` to a new authorizer instance, passing the options" do
            authorizer_instance.should_receive(adjective_method).with(user, :consistency => 'mushy')
            user.send(verb_method, model_instance, :consistency => 'mushy')
          end

        end

        describe "if not given an options hash" do

          it "delegates `#{adjective_method}` to a new authorizer instance, passing no options" do
            authorizer_instance.should_receive(adjective_method).with(user)
            user.send(verb_method, model_instance)
          end

        end

      end

    end

  end

end
