require 'spec_helper'
require 'support/example_model'
require 'support/user'

describe "integration from user through model to authorizer" do

  before :each do
    @user          = User.new
    @example_model = ExampleModel.new
  end

  describe "class methods" do

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "if given an options hash" do

        it "should delegate `#{adjective_method}` to its authorizer class, passing the options" do
          ExampleModel.authorizer.should_receive(adjective_method).with(@user, :lacking => 'nothing')
          @user.send(verb_method, ExampleModel, :lacking => 'nothing')
        end

      end

      describe "if not given an options hash" do

        it "should delegate `#{adjective_method}` to its authorizer class, passing no options" do
          ExampleModel.authorizer.should_receive(adjective_method).with(@user)
          @user.send(verb_method, @example_model)
        end

      end

    end

  end

  describe "instance methods" do

    before :each do
      @user          = User.new
      @example_model = ExampleModel.new
      @authorizer    = ExampleModel.authorizer.new(@example_model)
      ExampleModel.authorizer.stub(:new).and_return(@authorizer)
    end

    Authority.verbs.each do |verb|
      verb_method      = "can_#{verb}?"
      adjective        = Authority.abilities[verb]
      adjective_method = "#{adjective}_by?"

      describe "if given an options hash" do

        it "should delegate `#{adjective_method}` to a new authorizer instance, passing the options" do
          @authorizer.should_receive(adjective_method).with(@user, :consistency => 'mushy')
          @user.send(verb_method, @example_model, :consistency => 'mushy')
        end

      end

      describe "if not given an options hash" do
        
        it "should delegate `#{adjective_method}` to a new authorizer instance, passing no options" do
          @authorizer.should_receive(adjective_method).with(@user)
          @user.send(verb_method, @example_model)
        end

      end

    end

  end

end
