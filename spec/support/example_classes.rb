class ExampleUser
  include Authority::UserAbilities
end

class ExampleResource
  include Authority::Abilities
end

class ExampleResourceAuthorizer
end

module Namespaced
  class ExampleResourceAuthorizer
  end

  class ExampleResource
    include Authority::Abilities
  end

end

class OtherResource
  include Authority::Abilities
end

class ApplicationAuthorizer < Authority::Authorizer
  def self.readable_by?(user)
    true
  end
end



