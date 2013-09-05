require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/string/inflections'
require 'active_support/rescuable'
require 'forwardable'
require 'logger'
require 'authority/security_violation'

module Authority

  # NOTE: once this method is called, the library has started meta programming
  # and abilities should no longer be modified
  # @return [Hash] list of abilities, mapping verbs and adjectives, like :create => 'creatable'
  def self.abilities
    configuration.abilities.freeze
  end

  # @return [Array] keys from adjectives method
  def self.verbs
    abilities.keys
  end

  # @return [Array] values from adjectives method
  def self.adjectives
    abilities.values
  end

  # @param [Symbol] action
  # @param [Model] resource instance
  # @param [User] user instance
  # @param [Hash] options, arbitrary options hash to delegate to the authorizer
  # @raise [SecurityViolation] if user is not allowed to perform action on resource
  # @return [Model] resource instance
  def self.enforce(action, resource, user, options = {})
    unless action_authorized?(action, resource, user, options)
      raise SecurityViolation.new(user, action, resource)
    end
    resource
  end

  def self.action_authorized?(action, resource, user, options = {})
    resource_and_maybe_options = [resource, options].tap {|args| args.pop if args.last == {}}
    user.send("can_#{action}?", *resource_and_maybe_options)
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

  def self.logger
    @logger ||= configuration.logger
  end

  private

  def self.require_authority_internals!
    require 'authority/abilities'
    require 'authority/authorizer'
    require 'authority/user_abilities'
  end

end

require 'authority/configuration'
require 'authority/controller'
require 'authority/railtie' if defined?(Rails)
require 'authority/version'
