require 'spec_helper'
require 'support/example_classes'
require 'support/mock_rails'
require 'active_support/core_ext/proc'

describe Authority::Controller do

  class ExampleController
    def self.rescue_from(*args) ; end
    def self.before_filter(*args) ; end
  end

  # Get a fresh descendant class for each test, in case we've modified it
  let(:controller_class) { Class.new(ExampleController) }

  context "when including" do

    before :each do
      Authority::Controller.stub(:security_violation_callback).and_return(Proc.new {|exception| })
    end

    after :each do
      controller_class.send(:include, Authority::Controller)
    end

    it "specifies rescuing security violations with a standard callback" do
      controller_class.should_receive(:rescue_from).with(
        Authority::SecurityViolation, :with => Authority::Controller.security_violation_callback
      )
    end

  end

  context "after including" do

    let(:controller_class) do
      Class.new(ExampleController).tap do |c|
        c.send(:include, Authority::Controller)
      end
    end

    let(:resource_class) { ExampleResource }

    describe "the security violation callback" do

      it "calls whatever method on the controller that the configuration specifies" do
        # Here be dragons!
        fake_exception      = Exception.new
        controller_instance = controller_class.new
        # If a callback is passed to a controller's `rescue_from` method as the value for
        # the `with` option (like `SomeController.rescue_from FooException, :with => some_callback`),
        # Rails will use `instance_exec` to ensure that when the proc refers to
        # `self`, it will be the controller, not the proc itself.
        # I need this callback's `self` to be the controller for the purposes of
        # this test, so I'm stealing that behavior.

        Authority.configuration.security_violation_handler = :fire_ze_missiles
        controller_instance.should_receive(:fire_ze_missiles).with(fake_exception)
        controller_instance.instance_exec(fake_exception, &Authority::Controller.security_violation_callback)

      end
    end

    describe "the authority controller action map" do

      before(:each) { controller_class.instance_variable_set(:@authority_action_map, nil) }

      it "is created on demand" do
        expect(controller_class.authority_action_map).to be_a(Hash)
      end

      it "is created as a copy of the configured controller action map" do
        expect(controller_class.authority_action_map).to     eq(Authority.configuration.controller_action_map)
        expect(controller_class.authority_action_map).not_to be(Authority.configuration.controller_action_map)
      end

      it "is unique per controller" do
        child_controller = Class.new(controller_class)
        expect(child_controller.authority_action_map).not_to be(
          controller_class.authority_action_map
        )
      end

    end

    describe "class methods" do

      describe "authorize_actions_for" do

        it "allows specifying the class of the model to protect" do
          controller_class.authorize_actions_for(resource_class)
          expect(controller_class.authority_resource).to eq(resource_class)
        end

        it "allows specifying an instance method to find the class of the model to protect" do
          controller_class.authorize_actions_for(:finder_method)
          expect(controller_class.authority_resource).to eq(:finder_method)
        end

        it "sets up a before_filter, passing the options it was given" do
          filter_options = {:only => [:show, :edit, :update]}
          controller_class.should_receive(:before_filter).with(:run_authorization_check, filter_options)
          controller_class.authorize_actions_for(resource_class, filter_options)
        end

        it "passes the action hash to the `authority_action` method" do
          child_controller = Class.new(controller_class)
          new_actions = {:synthesize => :create, :annihilate => 'delete'}
          child_controller.should_receive(:authority_actions).with(new_actions)
          child_controller.authorize_actions_for(resource_class, :actions => new_actions)
        end

      end

      describe "authority_resource" do

        let(:child_controller) { Class.new(controller_class) }

        before :each do
          controller_class.authorize_actions_for(resource_class)
        end

        it "remembers what it was set to" do
          expect(controller_class.authority_resource).to eq(resource_class)
        end

        it "uses its parent controller's value by default" do
          expect(child_controller.authority_resource).to eq(resource_class)
        end

        it "can be modified without affecting the parent controller" do
          fancy_array = Class.new(Array)
          child_controller.authorize_actions_for(fancy_array)
          expect(child_controller.authority_resource).to eq(fancy_array)
          expect(controller_class.authority_resource).to eq(resource_class)
        end

      end

      describe "authority_action" do

        it "modifies this controller's authority action map" do
          new_actions = {:show => :display, :synthesize => :create, :annihilate => 'delete'}
          controller_class.authority_actions(new_actions)
          expect(controller_class.authority_action_map).to eq(
            Authority.configuration.controller_action_map.merge(new_actions)
          )
        end

        it "does not modify any other controller" do
          child_controller = Class.new(controller_class)
          child_controller.authority_actions(:smite => 'delete')
          expect(controller_class.authority_action_map[:smite]).to eq(nil)
        end

      end

    end

    describe "instance methods" do

      let(:controller_class) do
        Class.new(ExampleController).tap do |c|
          c.send(:include, Authority::Controller)
          c.authorize_actions_for(resource_class)
        end
      end

      let(:controller_instance) do
        controller_class.new.tap do |cc|
          cc.stub(Authority.configuration.user_method).and_return(user)
        end
      end

      let(:user) { ExampleUser.new }

      describe "run_authorization_check (used as a before_filter)" do

        context "if a resource class was specified" do

          it "checks authorization on the model specified" do
            controller_instance.should_receive(:authorize_action_for).with(resource_class)
            controller_instance.send(:run_authorization_check)
          end

        end

        context "if a method for determining the class was specified" do

          let(:resource_class) { Hash }
          let(:controller_class) do
            Class.new(ExampleController).tap do |c|
              c.send(:include, Authority::Controller)
              c.authorize_actions_for(:method_to_find_class)
            end
          end

          context "if the controller has such an instance method" do

            before :each do
              controller_instance.stub(:method_to_find_class).and_return(resource_class)
            end

            it "checks authorization on class returned by that method" do
              controller_instance.should_receive(:authorize_action_for).with(resource_class)
              controller_instance.send(:run_authorization_check)
            end

          end

          context "if the controller has no such instance method" do

            it "raises an exception" do
              expect{controller_instance.send(:run_authorization_check)}.to raise_error(
                Authority::Controller::MissingResource
              )
            end

          end

        end

        it "raises a MissingAction if there is no corresponding action for the controller" do
          controller_instance.stub(:action_name).and_return('sculpt')
          expect { controller_instance.send(:run_authorization_check) }.to raise_error(
            Authority::Controller::MissingAction
          )
        end

      end

      describe "authorize_action_for" do

        before(:each) { controller_instance.stub(:action_name).and_return(:destroy) }

        it "calls Authority.enforce to authorize the action" do
          Authority.should_receive(:enforce)
          controller_instance.send(:authorize_action_for, resource_class)
        end

        it "passes along any options it was given" do
          options = {:for => 'insolence'}
          Authority.should_receive(:enforce).with('delete', resource_class, user, options)
          controller_instance.send(:authorize_action_for, resource_class, options)
        end

      end

      describe "authority_user" do

        it "gets the user for the current request from the configured user_method" do
          controller_instance.should_receive(Authority.configuration.user_method)
          controller_instance.send(:authority_user)
        end

      end

      describe "authority_forbidden action" do

        let(:mock_error) { double(:message => 'oh noes! an error!') }

        it "logs an error" do
          Authority.logger.should_receive(:warn)
          controller_instance.stub(:render)
          controller_instance.send(:authority_forbidden, mock_error)
        end

        it "renders the public/403.html file" do
          forbidden_page = Rails.root.join('public/403.html')
          Authority.logger.stub(:warn)
          controller_instance.should_receive(:render).with(:file => forbidden_page, :status => 403, :layout => false)
          controller_instance.send(:authority_forbidden, mock_error)
        end

      end

    end

  end

end
