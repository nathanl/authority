class AbilityModel
  include Authority::Abilities
end

class AbilityModelAuthorizer < Authority::Authorizer
  def self.readable_by?(user)
    true
  end
end
