require 'spec_helper'
require 'support/example_classes'

describe "integration from user through model to authorizer" do

  let(:user)              { ExampleUser.new }
  let(:resource_class)    { ExampleResource }
  let(:resource_instance) { resource_class.new }

  describe "class methods" do

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "#{adjective_method}" do

        describe "if given an options hash" do

          it "delegates `#{adjective_method}` to its authorizer class, passing the options" do
            resource_class.authorizer.should_receive(adjective_method).with(user, :lacking => 'nothing')
            user.send(verb_method, resource_class, :lacking => 'nothing')
          end

        end

        describe "if not given an options hash" do

          it "delegates `#{adjective_method}` to its authorizer class, passing no options" do
            resource_class.authorizer.should_receive(adjective_method).with(user)
            user.send(verb_method, resource_instance)
          end

        end

      end

    end

  end

  describe "instance methods" do

    let!(:authorizer_instance) { resource_class.authorizer.new(resource_instance) }

    before :each do
      resource_class.authorizer.stub(:new).and_return(authorizer_instance)
    end

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "#{adjective_method}" do

        describe "if given an options hash" do

          it "delegates `#{adjective_method}` to a new authorizer instance, passing the options" do
            authorizer_instance.should_receive(adjective_method).with(user, :consistency => 'mushy')
            user.send(verb_method, resource_instance, :consistency => 'mushy')
          end

        end

        describe "if not given an options hash" do

          it "delegates `#{adjective_method}` to a new authorizer instance, passing no options" do
            authorizer_instance.should_receive(adjective_method).with(user)
            user.send(verb_method, resource_instance)
          end

        end

      end

    end

  end

end
