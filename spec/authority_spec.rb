require 'spec_helper'
require 'support/ability_model'
require 'support/user'

describe Authority do

  it "should have a default list of abilities" do
    Authority.abilities.should be_a(Hash)
  end

  it "should not allow modification of the Authority.abilities hash directly" do
    expect { Authority.abilities[:exchange] = 'fungible' }.to raise_error(RuntimeError, "can't modify frozen Hash")
  end

  it "should have a convenience accessor for the ability verbs" do
    Authority.verbs.sort.should eq([:create, :delete, :read, :update])
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

    it "should raise a SecurityTransgression if the action is unauthorized" do
      expect { Authority.enforce(:update, AbilityModel, @user) }.to raise_error(Authority::SecurityTransgression)
    end

    it "should not raise a SecurityTransgression if the action is authorized" do
      expect { Authority.enforce(:read, AbilityModel, @user) }.not_to raise_error(Authority::SecurityTransgression)
    end

  end

end
