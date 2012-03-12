require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module Authority
  ADJECTIVES = %w[creatable readable updatable deletable]
end

require 'authority/abilities'
require 'authority/authorizer'
require 'authority/version'
