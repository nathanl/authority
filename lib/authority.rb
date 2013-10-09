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
  end

  def self.action_authorized?(action, resource, user, options = {})
    raise MissingUser if user.nil?
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

  class MissingUser < StandardError
    def message
      "You tried to check authorization on `nil`. Authority doesn't know what
      `nil` is allowed to do.  There are two ways you can fix this.

      1. Authenticate before authorizing. If the user isn't signed in, force
      them to sign in before they can attempt any action that requires
      authorization.

      2. When the user is not signed in, return a Null Object instead of
      `nil`. (You could create an AnonymousUser class, for example.) It should
      respond to the normal methods Authority will call (like `can_delete?`),
      possibly by including `Authority::UserAbilities` and teaching your authorizers
      what an anonymous user can do.

      The downside of solution #2 is that a user who forgot to sign in will be
      told they are not authorized for an action they could normally do. This might
      be confusing.

      However, you might use both strategies in different parts of your application.
      "
    end
  end

end

require 'authority/configuration'
require 'authority/controller'
require 'authority/railtie' if defined?(Rails)
require 'authority/version'
