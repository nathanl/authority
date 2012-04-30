require 'spec_helper'
require 'support/ability_model'
require 'support/user'

describe Authority::Authorizer do

  before :each do
    @ability_model = AbilityModel.new
    @authorizer    = @ability_model.authorizer
    @user          = User.new
  end

  it "should take a resource instance in its initializer" do
    @authorizer.resource.should eq(@ability_model)
  end

  describe "instance methods" do

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        @authorizer.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to the corresponding class method by default" do
        @authorizer.class.should_receive(method_name).with(@user)
        @authorizer.send(method_name, @user)
      end

    end

  end

  describe "class methods" do

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        Authority::Authorizer.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to the authorizer's `default` method by default" do
        able = method_name.sub('_by?', '').to_sym
        Authority::Authorizer.should_receive(:default).with(able, @user)
        Authority::Authorizer.send(method_name, @user)
      end

    end

  end

  describe "the default method" do

    it "should return false" do
      Authority::Authorizer.default(:implodable, @user).should be_false
    end

  end

end
