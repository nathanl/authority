require 'spec_helper'
require 'support/example_model'
require 'support/example_controllers'
require 'support/mock_rails'
require 'support/user'
require 'active_support/core_ext/proc'

describe Authority::Controller do

  describe "the security violation callback" do

    it "calls whatever method on the controller that the configuration specifies" do
      # Here be dragons!
      @fake_exception    = Exception.new
      @sample_controller = SampleController.new
      # If a callback is passed to a controller's `rescue_from` method as the value for
      # the `with` option (like `SomeController.rescue_from FooException, :with => some_callback`),
      # Rails will use ActiveSupport's `Proc#bind` to ensure that when the proc refers to
      # `self`, it will be the controller, not the proc itself.
      # I need this callback's `self` to be the controller for the purposes of
      # this test, so I'm stealing that behavior.
      @callback = Authority::Controller.security_violation_callback.bind(@sample_controller)

      Authority.configuration.security_violation_handler = :fire_ze_missiles
      @sample_controller.should_receive(:fire_ze_missiles).with(@fake_exception)
      @callback.call(@fake_exception)
    end
  end

  context "when including" do

    before :each do
      Authority::Controller.stub(:security_violation_callback).and_return(Proc.new {|exception| })
    end

    it "specifies rescuing security violations with a standard callback" do
      SampleController.should_receive(:rescue_from).with(Authority::SecurityViolation, :with => Authority::Controller.security_violation_callback)
      SampleController.send(:include, Authority::Controller)
    end

  end

  context "after including" do

    describe "the authority controller action map" do

      before(:each) { ExampleController.instance_variable_set(:@authority_action_map, nil) }

      it "is created on demand" do
        expect(ExampleController.authority_action_map).to be_a(Hash)
      end

      it "is created as a copy of the configured controller action map" do
        expect(ExampleController.authority_action_map).to     eq(Authority.configuration.controller_action_map)
        expect(ExampleController.authority_action_map).not_to be(Authority.configuration.controller_action_map)
      end

      it "is unique per controller" do
        child_controller = Class.new(ExampleController)
        expect(child_controller.authority_action_map).not_to be(
          ExampleController.authority_action_map
        )
      end

    end

    describe "class methods" do

      describe "authorize_actions_for" do

        it "allows specifying the model to protect" do
          ExampleController.authorize_actions_for ExampleModel
          expect(ExampleController.authority_resource).to eq(ExampleModel)
        end

        it "sets up a before_filter, passing the options it was given" do
          @options = {:only => [:show, :edit, :update]}
          ExampleController.should_receive(:before_filter).with(:run_authorization_check, @options)
          ExampleController.authorize_actions_for ExampleModel, @options
        end

        it "passes the action hash to the `authority_action` method" do
          example_controller = Class.new(ExampleController)
          new_actions = {:synthesize => :create, :annihilate => 'delete'}
          example_controller.should_receive(:authority_actions).with(new_actions)
          example_controller.authorize_actions_for(ExampleModel, :actions => new_actions)
        end

      end

      describe "authority_action" do

        it "modifies this controller's authority action map" do
          example_controller = Class.new(ExampleController)
          new_actions = {:show => :display, :synthesize => :create, :annihilate => 'delete'}
          example_controller.authority_actions(new_actions)
          expect(example_controller.authority_action_map).to eq(
            Authority.configuration.controller_action_map.merge(new_actions)
          )
        end

        it "only affects the controller it's called in" do
          child_controller = Class.new(ExampleController)
          child_controller.authority_actions(:smite => 'delete')
          expect(ExampleController.authority_action_map[:smite]).to eq(nil)
        end

      end

    end

    describe "instance methods" do

      before :each do
        @user       = User.new
        @controller = ExampleController.new
        @controller.stub!(:action_name).and_return(:edit)
        @controller.stub!(Authority.configuration.user_method).and_return(@user)
      end

      it "checks authorization on the model specified" do
        # TODO - rethink this test and/or the test structure of this file.
        # Stubbing here is a code smell; it really reflects that
        # `run_authorization_check` is meant to be a before_filter, added
        # after some setup has been done by `authorize_actions_for`
        ExampleController.stub(:authority_resource).and_return(ExampleModel)
        @controller.should_receive(:authorize_action_for).with(ExampleModel)
        @controller.send(:run_authorization_check)
      end

      it "passes the options provided to `authorize_action_for` downstream" do
        @controller.stub!(:action_name).and_return(:destroy)
        Authority.should_receive(:enforce).with('delete', ExampleModel, @user, :for => 'context')
        @controller.send(:authorize_action_for, ExampleModel, :for => 'context')
      end

      it "raises a MissingAction if there is no corresponding action for the controller" do
        @controller.stub(:action_name).and_return('sculpt')
        expect { @controller.send(:run_authorization_check) }.to raise_error(Authority::Controller::MissingAction)
      end

      it "returns the authority_user for the current request by using the configured user_method" do
        @controller.should_receive(Authority.configuration.user_method)
        @controller.send(:authority_user)
      end

      describe "authority_forbidden action" do

        before :each do
          @mock_error = mock(:message => 'oh noes! an error!')
        end

        it "logs an error" do
          Authority.configuration.logger.should_receive(:warn)
          @controller.stub(:render)
          @controller.send(:authority_forbidden, @mock_error)
        end

        it "renders the public/403.html file" do
          forbidden_page = Rails.root.join('public/403.html')
          Authority.configuration.logger.stub(:warn)
          @controller.should_receive(:render).with(:file => forbidden_page, :status => 403, :layout => false)
          @controller.send(:authority_forbidden, @mock_error)
        end

      end

    end
    
  end

end
