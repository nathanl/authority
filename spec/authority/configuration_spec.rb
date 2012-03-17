require 'spec_helper'

describe Authority::Configuration do
  describe "the default configuration" do

    it "should have a default authorization strategy block" do
      Authority.configuration.default_strategy.should respond_to(:call)
    end

    it "should return false when calling the default authorization strategy block" do
      Authority.configuration.default_strategy.call(:action, Authority::Authorizer, User.new).should be_false
    end

    it "should have a default authority controller actions map" do
      Authority.configuration.controller_action_map.should be_a(Hash)
    end

    it "should have a default controller method for accessing the user object" do
      Authority.configuration.user_method.should eq(:current_user)
    end

    describe "logging security violations" do

      it "should log to standard error by default" do
        Authority.instance_variable_set :@configuration, nil
        null = File.exists?('/dev/null') ? '/dev/null' : 'NUL:' # Allow for Windows
        @logger = Logger.new(null)
        Logger.should_receive(:new).with(STDERR).and_return(@logger)
        Authority.configure
        Authority.configuration.logger
      end

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
