require 'spec_helper'
require 'support/ability_model'
require 'support/user'

describe Authority do

  it "should have a default list of abilities" do
    Authority.abilities.should be_a(Hash)
  end

  it "should not allow modification of the Authority.abilities hash directly" do
    expect { Authority.abilities[:exchange] = 'fungible' }.to raise_error(
      StandardError, /modify frozen/
    ) # can't modify frozen hash - exact error type and message depends on Ruby version
  end

  it "should have a convenience accessor for the ability verbs" do
    Authority.verbs.map(&:to_s).sort.should eq(['create', 'delete', 'read', 'update'])
  end

  it "should have a convenience accessor for the ability adjectives" do
    Authority.adjectives.sort.should eq(%w[creatable deletable readable updatable])
  end

  describe "configuring Authority" do

    it "should have a configuration accessor" do
      Authority.should respond_to(:configuration)
    end

    it "should have a `configure` method" do
      Authority.should respond_to(:configure)
    end

    it "should require the remainder of library internals after configuration" do
      Authority.should_receive(:require_authority_internals!)
      Authority.configure
    end
  end

  describe "enforcement" do

    before :each do
      @user = User.new
    end

    it "should raise a SecurityViolation if the action is unauthorized" do
      expect { Authority.enforce(:update, AbilityModel, @user) }.to raise_error(Authority::SecurityViolation)
    end

    it "should not raise a SecurityViolation if the action is authorized" do
      expect { Authority.enforce(:read, AbilityModel, @user) }.not_to raise_error(Authority::SecurityViolation)
    end

  end

end
