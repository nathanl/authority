require 'spec_helper'
require 'support/ability_model'
require 'support/actor'

describe ModelCitizen::Abilities do

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

  end

  describe "class methods" do

    %w[creatable readable updatable deletable].each do |verb|
      method_name = "#{verb}_by?"

      it "should respond to `#{method_name}`" do
        AbilityModel.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to its authorizer class" do
        pending
        AbilityModel.authorizer.should_receive(method_name).with(@actor)
        AbilityModel.send(method_name, @actor)
      end

    end

  end

  describe "instance methods" do

    before :each do
      @ability_model = AbilityModel.new
    end

    %w[creatable readable updatable deletable].each do |verb|
      method_name = "#{verb}_by?"

      it "should respond to `#{method_name}`" do
        @ability_model.should respond_to(method_name)
      end

      it "should delegate `#{method_name}`  to a new authorizer instance" do
        pending
      end

      it "should always create a new authorizer instance when checking `#{method_name}`"

    end
    
  end

end
