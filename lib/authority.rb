require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/string/inflections'
require 'logger'

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

  def self.enforce(action, resource, user)
    action_authorized = user.send("can_#{action}?", resource)
    unless action_authorized
      message = "#{user} is not authorized to #{action} this resource: #{resource.inspect}"
      raise SecurityTransgression.new(message)
    end
    resource
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

  class SecurityTransgression < StandardError ; end

end

require 'authority/configuration'
require 'authority/controller'
require 'authority/railtie' if defined?(Rails)
require 'authority/version'

