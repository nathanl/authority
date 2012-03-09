require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module ModelCitizen
  ADJECTIVES = %w[creatable readable updatable deletable]
end

require 'model_citizen/abilities'
require 'model_citizen/authorizer'
require 'model_citizen/version'
