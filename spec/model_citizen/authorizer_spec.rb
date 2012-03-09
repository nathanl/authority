require 'spec_helper'
require 'support/ability_model'

describe ModelCitizen::Authorizer do

  before :each do
    @ability_model = AbilityModel.new
  end

  it "should take a resource instance in its initializer" do
    @authorizer = ModelCitizen::Authorizer.new(@ability_model)
    @authorizer.resource.should eq(@ability_model)
  end

end

