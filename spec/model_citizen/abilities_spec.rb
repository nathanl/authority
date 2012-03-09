require 'spec_helper'
require 'support/ability_model'

describe ModelCitizen::Abilities do

  describe "class methods" do

    %w[creatable readable updatable deletable].each do |verb|
      method_name = "#{verb}_by?"

      it "should respond to `#{method_name}`" do
        AbilityModel.should respond_to(method_name)
      end

      it "should delegate `#{method_name}` to its authorizer class" do
        pending
      end

    end

  end

  describe "instance methods" do

    %w[creatable readable updatable deletable].each do |verb|
      method_name = "#{verb}_by?"

      it "should respond to `#{method_name}`" do
        pending
      end

      it "should delegate `#{method_name}`  to a new authorizer instance" do
        pending
      end

      it "should always create a new authorizer instance when checking `#{method_name}`"

    end
    
  end

end
