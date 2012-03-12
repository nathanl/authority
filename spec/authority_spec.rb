require 'spec_helper'
require 'support/user'

describe Authority do

  before :each do
    Authority.instance_variable_set(:@abilites, nil)
  end

  it "should have a default list of abilities" do
    Authority.abilities.should be_a(Hash)
  end

  it "should have a convenience accessor for the ability verbs" do
    Authority.verbs.sort.should eq([:create, :delete, :read, :update])
  end

  it "should have a convenience accessor for the ability adjectives" do
    Authority.adjectives.sort.should eq(%w[creatable deletable readable updatable])
  end

  describe "customizing Authority abilities" do
    before :each do
      Authority.instance_variable_set(:@default_strategy, nil)
      Authority.abilities[:eat] = 'edible'
    end

    it "should allow adding to the default list of abilities" do
      Authority.abilities[:eat].should eq('edible')
    end

    it "should add :eat to the list of verbs" do
      Authority.verbs.should include(:eat)
    end

    it "should add 'edible' to the list of adjectives" do
      Authority.adjectives.should include('edible')
    end
  end

  it "should have a default authorization strategy block" do
    Authority.default_strategy.should respond_to(:call)
  end

  it "should return false when calling the default authorization strategy block" do
    Authority.default_strategy.call(:action, Authority::Authorizer, User.new).should be_false
  end

  it "should allow customizing the authorization block" do
    Authority.default_strategy = Proc.new { |able, authorizer, user|
      true
    }
    Authority.default_strategy.call(:action, Authority::Authorizer, User.new).should be_true
  end
end
