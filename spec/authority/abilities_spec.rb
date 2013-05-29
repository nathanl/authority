require 'spec_helper'
require 'support/example_classes'

describe Authority::Abilities do

  let(:user)                      { ExampleUser.new }
  let(:resource_class)            { ExampleResource }
  let(:namespaced_resource_class) { Namespaced::SampleResource }
  let(:other_resource_class)      { OtherResource }

  describe "instance methods" do

    describe "authorizer_name" do

      it "has a class attribute getter" do
        expect(resource_class).to respond_to(:authorizer_name)
      end

      it "has a class attribute setter" do
        expect(resource_class).to respond_to(:authorizer_name=)
      end

      describe "by default" do

        context "when there is an authorizer with a name like the resource's" do

          it "uses that authorizer" do
            expect(resource_class.authorizer_name).to eq("ExampleResourceAuthorizer")
          end

          it "respects namespaces when it's looking" do
            expect(namespaced_resource_class.authorizer_name).to eq("Namespaced::SampleResourceAuthorizer")
          end

        end

        context "when there is no authorizer with a name like the resource's" do

          it "uses 'ApplicationAuthorizer'" do
            expect(other_resource_class.authorizer_name).to eq("ApplicationAuthorizer")
          end

        end

      end

    end

    describe "authorizer" do

      it "wraps the authorizer with wraper" do
        resource_class.instance_variable_set(:@authorizer, nil)
        resource_class.should_receive(:wrap_authorizer)
        resource_class.authorizer
      end

      it "memoizes the authorizer to avoid reconstantizing" do
        resource_class.authorizer
        resource_class.should_not_receive(:wrap_authorizer)
        resource_class.authorizer
      end

      it "raises a friendly error if the authorizer doesn't exist" do
        class NoAuthorizerModel < resource_class; end ;
        NoAuthorizerModel.instance_variable_set(:@authorizer, nil)
        NoAuthorizerModel.authorizer_name = 'NonExistentAuthorizer'
        expect { NoAuthorizerModel.authorizer }.to raise_error(Authority::NoAuthorizerError)
      end

    end

  end

  context 'authorizer wraper' do
    specify 'authorizer should be wraped with wraper class' do
      resource_class.authorizer.name.should == 'ExampleResourceAuthorizerWraper'
    end

    specify 'authorizer wraper name for application authorither should be uniq' do
      other_resource_class.authorizer.name.should == 'OtherResourceAuthorizerWraper'
    end

    describe '.resourse' do
      specify 'resource class should respond to .resourse' do
        resource_class.authorizer.should respond_to(:resource)
      end

      specify '.resource should return resource class' do
        resource_class.authorizer.resource.should == resource_class
      end
    end
  end

  describe "class methods" do

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "responds to `#{method_name}`" do
        expect(resource_class).to respond_to(method_name)
      end

      describe "#{method_name}" do

        context "when given an options hash" do

          it "delegates `#{method_name}` to its authorizer class, passing the options" do
            resource_class.authorizer.should_receive(method_name).with(user, :lacking => 'nothing')
            resource_class.send(method_name, user, :lacking => 'nothing')
          end

        end

        context "when not given an options hash" do

          it "delegates `#{method_name}` to its authorizer class, passing no options" do
            resource_class.authorizer.should_receive(method_name).with(user)
            resource_class.send(method_name, user)
          end

        end

      end

    end

  end

  describe "instance methods" do

    let(:resource_instance) { resource_class.new }

    before :each do
      @authorizer = resource_class.authorizer.new(resource_instance)
    end

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "responds to `#{method_name}`" do
        expect(resource_instance).to respond_to(method_name)
      end

      describe "#{method_name}" do

        context "when given an options hash" do

          it "delegates `#{method_name}` to a new authorizer instance, passing the options" do
            resource_class.authorizer.stub(:new).and_return(@authorizer)
            @authorizer.should_receive(method_name).with(user, :with => 'mayo')
            resource_instance.send(method_name, user, :with => 'mayo')
          end

        end

        context "when not given an options hash" do

          it "delegates `#{method_name}` to a new authorizer instance, passing no options" do
            resource_class.authorizer.stub(:new).and_return(@authorizer)
            @authorizer.should_receive(method_name).with(user)
            resource_instance.send(method_name, user)
          end

        end

      end

    end

    it "provides an accessor for its authorizer" do
      expect(resource_instance).to respond_to(:authorizer)
    end

    # When checking instance methods, we want to ensure that every check uses a new
    # instance of the authorizer. Otherwise, you might check, make a change to the
    # model instance, check again, and get an outdated answer.
    it "always creates a new authorizer instance when accessing the authorizer" do
      resource_instance.class.authorizer.should_receive(:new).with(resource_instance).twice
      2.times { resource_instance.authorizer }
    end

  end

end
