require 'spec_helper'
require 'support/ability_model'

describe ModelCitizen::Authorizer do

  before :each do
    @ability_model = AbilityModel.new
    @authorizer = ModelCitizen::Authorizer.new(@ability_model)
  end

  it "should take a resource instance in its initializer" do
    @authorizer.resource.should eq(@ability_model)
  end

  describe "class methods" do

    ModelCitizen::ADJECTIVES.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        ModelCitizen::Authorizer.should respond_to(method_name)
      end

    end

  end

  describe "instance methods" do

    ModelCitizen::ADJECTIVES.each do |adjective|
      method_name = "#{adjective}_by?"

      it "should respond to `#{method_name}`" do
        @authorizer.should respond_to(method_name)
      end

    end

  end

end

