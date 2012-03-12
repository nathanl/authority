require 'spec_helper'
require 'support/ability_model'

describe Authority::Authorizer do

  before :each do
    @ability_model = AbilityModel.new
    @authorizer = Authority::Authorizer.new(@ability_model)
  end

  it "should take a resource instance in its initializer" do
    @authorizer.resource.should eq(@ability_model)
  end

  describe "class methods" do

    Authority::ADJECTIVES.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        Authority::Authorizer.should respond_to(method_name)
      end

    end

  end

  describe "instance methods" do

    Authority::ADJECTIVES.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        @authorizer.should respond_to(method_name)
      end

    end

  end

end

