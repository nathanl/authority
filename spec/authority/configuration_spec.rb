require 'spec_helper'

describe Authority::Configuration do
  describe "the default configuration" do

    it "should have a default authorization strategy block" do
      Authority.configuration.default_strategy.should respond_to(:call)
    end

    it "should return false when calling the default authorization strategy block" do
      Authority.configuration.default_strategy.call(:action, Authority::Authorizer, User.new).should be_false
    end

  end

  describe "customizing the configuration" do
    before :all do 
      Authority.instance_variable_set :@configuration, nil
      Authority.configure do |config|
        config.abilities[:eat]  = 'edible'
        config.default_strategy = Proc.new { |able, authorizer, user|
          true
        }
      end

      after :all do
        Authority.instance_variable_set :@configuration, nil
        Authority.configure
      end

      it "should allow customizing the authorization block" do
        Authority.configuration.default_strategy.call(:action, Authority::Authorizer, User.new).should be_true
      end

      # This shouldn't be used during runtime, only during configuration
      # It won't do anything outside of configuration anyway
      it "should allow adding to the default list of abilities" do
        Authority.configuration.abilities[:eat].should eq('edible')
      end

    end
  end
end
