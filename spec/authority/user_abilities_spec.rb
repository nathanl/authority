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

    it "should delegate the authorization check to the resource provided" do
      @ability_model.should_receive("#{Authority.abilities[verb]}_by?").with(@user)
      @user.send(method_name, @ability_model)
    end
  end

end
