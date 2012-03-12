require 'spec_helper'

describe Authority do
  it "should have a constant of abilities" do
    Authority::ADJECTIVES.should be_an(Array)
  end
end
