require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module Authority

  def self.abilities
    @abilities ||= {
      :create => 'creatable',
      :read   => 'readable',
      :update => 'updatable',
      :delete => 'deletable'
    }
  end

  def self.verbs
    abilities.keys
  end

  def self.adjectives
    abilities.values
  end

  def self.default_strategy
    @default_strategy ||= Proc.new { |able, authorizer, user|
      false
    }
  end

  def self.default_strategy=(value)
    @default_strategy = value
  end
end

require 'authority/abilities'
require 'authority/authorizer'
require 'authority/user_abilities'
require 'authority/version'
