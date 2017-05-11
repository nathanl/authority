require 'spec_helper'
require 'support/example_classes'
require 'support/mock_rails'
require 'set'

describe Authority::Controller do

  class ExampleController
    def self.rescue_from(*args) ; end
    def self.before_filter(*args) ; end
  end

  # Get a fresh descendant class for each test, in case we've modified it
  let(:controller_class) { Class.new(ExampleController) }

  context "when including" do

    before :each do
      allow(Authority::Controller).to receive(:security_violation_callback).and_return(Proc.new {|exception| })
    end

    after :each do
      controller_class.send(:include, Authority::Controller)
    end

    it "specifies rescuing security violations with a standard callback" do
      expect(controller_class).to receive(:rescue_from).with(
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
        expect(controller_instance).to receive(:fire_ze_missiles).with(fake_exception)
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

        let(:child_controller) { Class.new(controller_class) }

        let(:rails5_controller) do
          Class.new(controller_class) do
            def self.before_action(*args) ; end
          end
        end

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
          expect(controller_class).to receive(:before_filter).with(:run_authorization_check, filter_options)
          controller_class.authorize_actions_for(resource_class, filter_options)
        end

        it "prefers to set up a before_action over before_filter, passing the options it was given" do
          filter_options = {:only => [:show, :edit, :update]}
          expect(rails5_controller).to receive(:before_action).with(:run_authorization_check, filter_options)
          rails5_controller.authorize_actions_for(resource_class, filter_options)
        end

        it "if :all_actions option is given, it overrides the action hash to use the action given" do
          overridden_action_map = controller_class.authority_action_map
          overridden_action_map.update(overridden_action_map) {|k,v| v = :annihilate}
          child_controller.authorize_actions_for(resource_class, :all_actions => :annihilate)
          expect(child_controller.authority_action_map).to eq(overridden_action_map)
        end

        it "passes the action hash to the `add_actions` method" do
          new_actions = {:synthesize => :create, :annihilate => 'delete'}
          expect(child_controller).to receive(:add_actions).with(new_actions)
          child_controller.authorize_actions_for(resource_class, :actions => new_actions)
        end

        it "updates the action map if :actions option is given" do
          updated_map = child_controller.authority_action_map
          updated_map[:synthesize] = :create
          new_actions = {:synthesize => :create}
          child_controller.authorize_actions_for(resource_class, :actions => new_actions)
          expect(child_controller.authority_action_map).to eq(updated_map)
        end

        it "if :opts option is given, it extracts extra options for the authorization check" do
          controller_class.authorize_actions_for(resource_class, :args => [:foo, :bar])
          expect(controller_class.authority_arguments).to eq([:foo, :bar])
        end

        it "if :opts option wasn't given, no extra options are set" do
          controller_class.authorize_actions_for(resource_class)
          expect(controller_class.authority_arguments?).not_to be true
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

      describe "authority_actions" do

        it "modifies this controller's authority action map" do
          new_actions = {:show => :display, :synthesize => :create, :annihilate => 'delete'}
          controller_class.authority_actions(new_actions)
          expect(controller_class.authority_action_map).to eq(
            Authority.configuration.controller_action_map.merge(new_actions)
          )
        end

        it "forces to use a single method when :all_actions option is given" do
          force_actions = {:all_actions => :utilize}
          controller_class.authority_actions(force_actions)
          expect(controller_class.authority_action_map.values.uniq).to eq([:utilize])
        end

        it "can be used multiple times; each usage appends methods to authority_action_map" do
          controller_class.authority_actions({:all_actions  => :utilize})
          controller_class.authority_actions({:synthesize   => :create})
          controller_class.authority_actions({:transmogrify => :update})
          expect(controller_class.authority_action_map.values.uniq.to_set).to eq([:create, :update, :utilize].to_set)
          expect(controller_class.authority_action_map[:synthesize]).to eq(:create)
        end

        it "does not modify any other controller" do
          child_controller = Class.new(controller_class)
          child_controller.authority_actions(:smite => 'delete')
          expect(controller_class.authority_action_map[:smite]).to eq(nil)
        end

      end

      describe "ensure_authorization_performed" do

        let(:controller_instance) { controller_class.new }

        before(:each) do
          allow(controller_instance).to receive(:class).and_return("FooController")
          allow(controller_instance).to receive(:action_name).and_return(:bar)
        end

        it "sets up an after_filter, passing the options it was given" do
          filter_options = {:only => [:show, :edit, :update]}
          expect(controller_class).to receive(:after_filter).with(filter_options)
          controller_class.ensure_authorization_performed(filter_options)
        end

        it "triggers AuthorizationNotPerformed in after filter" do
          allow(controller_class).to receive(:after_filter).and_yield(controller_instance)
          expect {
            controller_class.ensure_authorization_performed
          }.to raise_error(Authority::Controller::AuthorizationNotPerformed)
        end

        it "AuthorizationNotPerformed error has meaningful message" do
          allow(controller_class).to receive(:after_filter).and_yield(controller_instance)
          expect {
            controller_class.ensure_authorization_performed
          }.to raise_error("No authorization was performed for FooController#bar")
        end

        it "does not trigger AuthorizationNotPerformed when :if is false" do
          allow(controller_instance).to receive(:authorize?) { false }
          allow(controller_class).to receive(:after_filter).with({}).and_yield(controller_instance)
          expect {
            controller_class.ensure_authorization_performed(:if => :authorize?)
          }.not_to raise_error()
        end

        it "does not trigger AuthorizationNotPerformed when :unless is true" do
          allow(controller_instance).to receive(:skip_authorization?) { true }
          allow(controller_class).to receive(:after_filter).with({}).and_yield(controller_instance)
          expect {
            controller_class.ensure_authorization_performed(:unless => :skip_authorization?)
          }.not_to raise_error()
        end

        it "does not raise error when #authorization_performed is true" do
          controller_instance.authorization_performed = true
          allow(controller_class).to receive(:after_filter).with({}).and_yield(controller_instance)
          expect {
            controller_class.ensure_authorization_performed
          }.not_to raise_error()
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
          allow(cc).to receive(Authority.configuration.user_method).and_return(user)
        end
      end

      let(:user) { ExampleUser.new }

      describe "run_authorization_check (used as a before_filter)" do

        context "if a resource class was specified" do

          it "checks authorization on the model specified" do
            expect(controller_instance).to receive(:authorize_action_for).with(resource_class)
            controller_instance.send(:run_authorization_check)
          end

        end

        context "if extra opts were specified" do

          let(:resource_class) { Hash }
          let(:controller_class) do
            Class.new(ExampleController).tap do |c|
              c.send(:include, Authority::Controller)
              c.authorize_actions_for(:method_to_find_class, args: [:extra, :args])
            end
          end
          
          before :each do
            allow(controller_instance).to receive(:method_to_find_class).and_return(resource_class)
          end

          it "uses extra args in authorization check" do
            expect(controller_instance).to receive(:authorize_action_for).with(resource_class, :extra, :args)
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

            context "and the method returns a class" do
              before :each do
                allow(controller_instance).to receive(:method_to_find_class).and_return(resource_class)
              end

              it "checks authorization on that class" do
                expect(controller_instance).to receive(:authorize_action_for).with(resource_class)
                controller_instance.send(:run_authorization_check)
              end

              it "does not call to_a on that class" do
                expect(controller_instance).to receive(:authorize_action_for).with(resource_class)
                # *resource is syntactic sugar for resource.to_a
                expect(resource_class).not_to receive(:to_a)
                controller_instance.send(:run_authorization_check)
              end
            end

            context "and the method returns an array containing a class and some options" do
              let(:some_options) { { :a => 1, :b => 2 } }

              before :each do
                allow(controller_instance).to receive(:method_to_find_class).and_return([resource_class, some_options])
              end

              it "checks authorization on that class and passes the options" do
                expect(controller_instance).to receive(:authorize_action_for).with(resource_class, some_options)
                controller_instance.send(:run_authorization_check)
              end
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
          allow(controller_instance).to receive(:action_name).and_return('sculpt')
          expect { controller_instance.send(:run_authorization_check) }.to raise_error(
            Authority::Controller::MissingAction
          )
        end

      end

      describe "authorize_action_for" do

        before(:each) { allow(controller_instance).to receive(:action_name).and_return(:destroy) }

        it "calls Authority.enforce to authorize the action" do
          expect(Authority).to receive(:enforce)
          controller_instance.send(:authorize_action_for, resource_class)
        end

        it "passes along any options it was given" do
          options = {:for => 'insolence'}
          expect(Authority).to receive(:enforce).with('delete', resource_class, user, options)
          controller_instance.send(:authorize_action_for, resource_class, options)
        end

        it "passes options set by authority_actions" do
          options = {:for => 'insolence'}
          controller_class.authority_actions({:destroy => ['delete', options]})
          Authority.should_receive(:enforce).with('delete', resource_class, user, options)
          controller_instance.send(:authorize_action_for, resource_class)
        end

        it "sets correct authorization flag" do
          allow(Authority).to receive(:enforce)
          controller_instance.send(:authorize_action_for, resource_class)
          expect(controller_instance.authorization_performed?).to eq(true)
        end

      end

      describe "authority_user" do

        it "gets the user for the current request from the configured user_method" do
          expect(controller_instance).to receive(Authority.configuration.user_method)
          controller_instance.send(:authority_user)
        end

      end

      describe "authority_forbidden action" do

        let(:mock_error) { double(:message => 'oh noes! an error!') }

        it "logs an error" do
          expect(Authority.logger).to receive(:warn)
          allow(controller_instance).to receive(:render)
          controller_instance.send(:authority_forbidden, mock_error)
        end

        it "renders the public/403.html file" do
          forbidden_page = Rails.root.join('public/403.html')
          allow(Authority.logger).to receive(:warn)
          expect(controller_instance).to receive(:render).with(:file => forbidden_page, :status => 403, :layout => false)
          controller_instance.send(:authority_forbidden, mock_error)
        end

      end

    end

  end

end
