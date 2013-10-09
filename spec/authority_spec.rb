require 'spec_helper'
require 'support/example_classes'

describe Authority do

  it "has a default list of abilities" do
    expect(Authority.abilities).to be_a(Hash)
  end

  it "does not allow modification of the Authority.abilities hash directly" do
    expect { Authority.abilities[:exchange] = 'fungible' }.to raise_error(
      StandardError, /modify frozen/
    ) # can't modify frozen hash - exact error type and message depends on Ruby version
  end

  it "has a convenience accessor for the ability verbs" do
    expect(Authority.verbs.map(&:to_s).sort).to eq(%w[create delete read update])
  end

  it "has a convenience accessor for the ability adjectives" do
    expect(Authority.adjectives.sort).to eq(%w[creatable deletable readable updatable])
  end

  describe "configuring Authority" do

    it "has a configuration accessor" do
      expect(Authority).to respond_to(:configuration)
    end

    it "has a `configure` method" do
      expect(Authority).to respond_to(:configure)
    end

    it "requires the remainder of library internals after configuration" do
      Authority.should_receive(:require_authority_internals!)
      Authority.configure
    end
  end

  describe "enforcement" do

    let(:resource_class) { ExampleResource }

    describe "when given a user object" do

      let(:user)           { ExampleUser.new }

      describe "when given options" do

        it "checks the user's authorization, passing along the options" do
          options = { :for => 'context' }
          user.should_receive(:can_delete?).with(resource_class, options).and_return(true)
          Authority.enforce(:delete, resource_class, user, options)
        end

      end

      describe "when not given options" do

        it "checks the user's authorization, passing no options" do
          user.should_receive(:can_delete?).with(resource_class).and_return(true)
          Authority.enforce(:delete, resource_class, user)
        end

      end

      it "raises a SecurityViolation if the action is unauthorized" do
        expect { Authority.enforce(:update, resource_class, user) }.to raise_error(Authority::SecurityViolation)
      end

      it "doesn't raise a SecurityViolation if the action is authorized" do
        expect { Authority.enforce(:read, resource_class, user) }.not_to raise_error()
      end

    end

    describe "when given a nil user" do

      let(:user) { nil }

      it "raises a helpful error" do
        expect { Authority.enforce(:update, resource_class, user) }.to raise_error(Authority::MissingUser)
      end

    end

  end

  describe Authority::SecurityViolation do

    let(:user)               { :"Cap'n Ned" }
    let(:action)             { :keelhaul }
    let(:resource)           { :houseplant }
    let(:security_violation) { Authority::SecurityViolation.new(user, action, resource) }

    it "has a reader for the user" do
      expect(security_violation.user).to eq(user)
    end

    it "has a reader for the action" do
      expect(security_violation.action).to eq(action)
    end

    it "has a reader for the resource" do
      expect(security_violation.resource).to eq(resource)
    end

    it "uses them all in its message" do
      expect(security_violation.message).to eq("#{user} is not authorized to #{action} this resource: #{resource}")
    end

  end

end
