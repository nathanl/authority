require 'spec_helper'
require 'support/example_model'
require 'support/user'

describe Authority::UserAbilities do

  before :each do
    @example_model = ExampleModel.new
    @user          = User.new
  end

  describe "can_(verb)? methods" do

    Authority.verbs.each do |verb|
      method_name = "can_#{verb}?"

      it "should define the `#{method_name}` method" do
        @user.should respond_to(method_name)
      end

      describe "if given options" do

        it "should delegate the authorization check to the resource, passing the options" do
          @example_model.should_receive("#{Authority.abilities[verb]}_by?").with(@user, :size => 'wee')
          @user.send(method_name, @example_model, :size => 'wee')
        end

      end

      describe "if not given options" do

        it "should delegate the authorization check to the resource, passing no options" do
          @example_model.should_receive("#{Authority.abilities[verb]}_by?").with(@user)
          @user.send(method_name, @example_model)
        end

      end

    end

  end

  describe "authorized_to? method" do

    it "checks with ApplicationAuthorizer" do
      ApplicationAuthorizer.should_receive(:authorizes?).with(:mimic_lemurs, @user)
      @user.authorized_to?(:mimic_lemurs)
    end

  end

end
