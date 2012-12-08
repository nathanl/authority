require 'spec_helper'
require 'support/example_classes'

describe Authority::UserAbilities do

  let(:model_instance) { ExampleModel.new }
  let(:user)           { User.new }

  describe "using `can_{verb}?` methods to check permissions on a resource" do

    Authority.verbs.each do |verb|
      method_name = "can_#{verb}?"

      it "defines the `#{method_name}` method" do
        expect(user).to respond_to(method_name)
      end

      describe "if given options" do

        it "delegates the authorization check to the resource, passing the options" do
          model_instance.should_receive("#{Authority.abilities[verb]}_by?").with(user, :size => 'wee')
          user.send(method_name, model_instance, :size => 'wee')
        end

      end

      describe "if not given options" do

        it "delegates the authorization check to the resource, passing no options" do
          model_instance.should_receive("#{Authority.abilities[verb]}_by?").with(user)
          user.send(method_name, model_instance)
        end

      end

    end

  end

  describe "using `can?` for non-resource-specific checks" do

    it "checks with ApplicationAuthorizer" do
      ApplicationAuthorizer.should_receive(:can_mimic_lemurs?).with(user)
      user.can?(:mimic_lemurs)
    end

  end

end
