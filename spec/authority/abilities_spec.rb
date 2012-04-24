require 'spec_helper'
require 'support/ability_model'
require 'support/no_authorizer_model'
require 'support/user'

describe Authority::Abilities do

  before :each do
    @user = User.new
  end

  describe "authorizer" do

    it "should have a class attribute getter for authorizer_name" do
      AbilityModel.should respond_to(:authorizer_name)
    end

    it "should have a class attribute setter for authorizer_name" do
      AbilityModel.should respond_to(:authorizer_name=)
    end

    it "should have a default authorizer_name of '(ClassName)Authorizer'" do
      AbilityModel.authorizer_name.should eq("AbilityModelAuthorizer")
    end

    it "should constantize the authorizer name as the authorizer" do
      AbilityModel.instance_variable_set(:@authorizer, nil)
      AbilityModel.authorizer_name.should_receive(:constantize)
      AbilityModel.authorizer
    end

    it "should memoize the authorizer to avoid reconstantizing" do
      AbilityModel.authorizer
      AbilityModel.authorizer_name.should_not_receive(:constantize)
      AbilityModel.authorizer
    end

    it "should raise a friendly error if the authorizer doesn't exist" do
      expect { NoAuthorizerModel.authorizer }.to raise_error(Authority::NoAuthorizerError)
    end

  end

  describe "class methods" do

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        AbilityModel.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to its authorizer class" do
        AbilityModel.authorizer.should_receive(method_name).with(@user)
        AbilityModel.send(method_name, @user)
      end

    end

  end

  describe "instance methods" do

    before :each do
      @ability_model = AbilityModel.new
      @authorizer    = AbilityModel.authorizer.new(@ability_model)
    end

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        @ability_model.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to a new authorizer instance" do
        AbilityModel.authorizer.stub(:new).and_return(@authorizer)
        @authorizer.should_receive(method_name).with(@user)
        @ability_model.send(method_name, @user)
      end

    end

    it "should provide an accessor for its authorizer" do
      @ability_model.should respond_to(:authorizer)
    end

    # TODO: Nathan will comment more clearly in the future
    # aka "don't memoize" (to prevent dirty models from contaminating authorization)
    it "should always create a new authorizer instance when accessing the authorizer" do
      @ability_model.class.authorizer.should_receive(:new).with(@ability_model).twice
      2.times { @ability_model.authorizer }
    end

  end

end
