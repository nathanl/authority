require 'spec_helper'

describe Authority::Configuration do
  describe "the default configuration" do

    it "has a default authority controller actions map" do
      expect(Authority.configuration.controller_action_map).to be_a(Hash)
    end

    it "has a default controller method for accessing the user object" do
      expect(Authority.configuration.user_method).to eq(:current_user)
    end

    describe "logging security violations" do

      it "logs to standard error by default" do
        Authority.instance_variable_set :@configuration, nil
        null = File.exists?('/dev/null') ? '/dev/null' : 'NUL:' # Allow for Windows
        logger = Logger.new(null)
        Logger.should_receive(:new).with(STDERR).and_return(logger)
        Authority.configure
        Authority.logger
      end

    end

  end

  describe "customizing the configuration" do
    before :all do
      Authority.instance_variable_set :@configuration, nil
      Authority.configure do |config|
        config.abilities[:eat]  = 'edible'
      end

      after :all do
        Authority.instance_variable_set :@configuration, nil
        Authority.configure
      end

      # This shouldn't be used during runtime, only during configuration
      # It won't do anything outside of configuration anyway
      it "allows adding to the default list of abilities" do
        expect(Authority.configuration.abilities[:eat]).to eq('edible')
      end

    end
  end

  describe "helping those upgrading from versions prior to 2.0" do

    before :all do
      Authority.instance_variable_set :@configuration, nil
    end

    it "raises a helpful exception if `config.default_strategy` is called" do
      expect { Authority.configure { |config| config.default_strategy = Proc.new { false }}}.to raise_error(
        ArgumentError, "`config.default_strategy=` was removed in Authority 2.0; see README and CHANGELOG"
      )
    end

  end
end
