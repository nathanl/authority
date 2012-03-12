require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module Authority

  # NOTE: once this method is called, the library has started meta programming
  # and abilities should no longer be modified
  def self.abilities
    configuration.abilities.freeze
  end

  def self.verbs
    abilities.keys
  end

  def self.adjectives
    abilities.values
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    require_authority_internals!

    configuration
  end

  private

  def self.require_authority_internals!
    require 'authority/abilities'
    require 'authority/authorizer'
    require 'authority/user_abilities'
  end

end

require 'authority/configuration'
require 'authority/version'

