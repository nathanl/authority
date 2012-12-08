class ExampleUser
  include Authority::UserAbilities
end

class ExampleResource
  include Authority::Abilities
end

class ApplicationAuthorizer < Authority::Authorizer
  def self.readable_by?(user)
    true
  end
end
