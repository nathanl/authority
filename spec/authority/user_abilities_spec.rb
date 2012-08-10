require 'spec_helper'
require 'support/ability_model'
require 'support/user'

describe Authority::UserAbilities do

  before :each do
    @ability_model = AbilityModel.new
    @user          = User.new
  end

  Authority.verbs.each do |verb|
    method_name = "can_#{verb}?"

    it "should define the `#{method_name}` method" do
      @user.should respond_to(method_name)
    end

    describe "if given options" do

      it "should delegate the authorization check to the resource, passing the options" do
        @ability_model.should_receive("#{Authority.abilities[verb]}_by?").with(@user, :size => 'wee')
        @user.send(method_name, @ability_model, :size => 'wee')
      end

    end

    describe "if not given options" do

      it "should delegate the authorization check to the resource, passing no options" do
        @ability_model.should_receive("#{Authority.abilities[verb]}_by?").with(@user)
        @user.send(method_name, @ability_model)
      end

    end

  end

end
