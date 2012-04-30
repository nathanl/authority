class AbilityModel
  include Authority::Abilities
end

class ApplicationAuthorizer < Authority::Authorizer
  def self.readable_by?(user)
    true
  end
end
