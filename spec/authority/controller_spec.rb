require 'spec_helper'
require 'support/ability_model'
require 'support/example_controllers'
require 'support/mock_rails'
require 'support/user'

describe Authority::Controller do

  describe "when including" do
    it "should specify rescuing security transgressions" do
      SampleController.should_receive(:rescue_from).with(Authority::SecurityTransgression, :with => :authority_forbidden)
      SampleController.send(:include, Authority::Controller)
    end

    it "should create a copy of the default controller action map" do
      SampleController.send(:include, Authority::Controller)
      Authority.configuration.controller_action_map.object_id.should_not eql(SampleController.authority_action_map.object_id)
    end
  end

  describe "after including" do
    describe "DSL (class) methods" do
      it "should allow specifying the model to protect" do
        ExampleController.authorize_actions_on AbilityModel
        ExampleController.authority_resource.should eq(AbilityModel)
      end

      it "should pass the options provided to the before filter that is set up" do
        @options = {:only => [:show, :edit, :update]}
        ExampleController.should_receive(:before_filter).with(:run_authorization_check, @options)
        ExampleController.authorize_actions_on AbilityModel, @options
      end

      it "should give the controller its own copy of the authority actions map" do
        ExampleController.authorize_actions_on AbilityModel
        ExampleController.authority_action_map.should be_a(Hash)
        ExampleController.authority_action_map.should_not be(Authority.configuration.controller_action_map)
      end

      it "should allow specifying the authority action map in the `authorize_actions_on` declaration" do
        ExampleController.authorize_actions_on AbilityModel, :actions => {:eat => 'delete'}
        ExampleController.authority_action_map[:eat].should eq('delete')
      end

      it "should have a write into the authority actions map usuable in a DSL format" do
        ExampleController.authority_action :smite => 'delete'
        ExampleController.authority_action_map[:smite].should eq('delete')
      end
    end

    describe "instance methods" do
      before :each do 
        @user       = User.new
        @controller = ExampleController.new
        @controller.stub!(:action_name).and_return(:edit)
        @controller.stub!(Authority.configuration.user_method).and_return(@user)
      end

      it "should check authorization on the model specified" do
        @controller.should_receive(:authorize_action_on).with(AbilityModel, @user)
        @controller.send(:run_authorization_check)
      end

      it "should raise a SecurityTransgression if authorization fails" do
        expect { @controller.send(:run_authorization_check) }.to raise_error(Authority::SecurityTransgression)
      end

      it "should raise a MissingAction if there is no corresponding action for the controller" do
        @controller.stub(:action_name).and_return('sculpt')
        expect { @controller.send(:run_authorization_check) }.to raise_error(Authority::Controller::MissingAction)
      end

      describe "in controllers not using any class methods that inherited from a controller including authority" do
        it "should automatically have a new copy of the authority_action_map" do
          @controller = InstanceController.new
          @controller.class.authority_action_map.should eq(Authority.configuration.controller_action_map)
        end
      end

      describe "authority_forbidden action" do

        before :each do
          @mock_error = mock(:message => 'oh noes! an error!')
        end

        it "should log an error" do
          Authority.configuration.logger.should_receive(:warn)
          @controller.stub(:render)
          @controller.send(:authority_forbidden, @mock_error)
        end

        it "should render the public/403.html file" do
          forbidden_page = Rails.root.join('public/403.html')
          @controller.should_receive(:render).with(:file => forbidden_page, :status => 403, :layout => false)
          @controller.send(:authority_forbidden, @mock_error)
        end
      end
    end
  end

  describe "when extending" do
    it "should allow the child class to edit the controller action map without effecting the parent class" do
      DummyController.authority_action :erase => 'delete'
      ExampleController.authority_action_map[:erase].should be_nil
    end
  end

end

