$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'model_citizen'

RSpec.configure do |config|
  config.mock_with :rspec
end
