module Authority
  module UserAbilities

    # Should be included into whatever class represents users in an app.
    # Provides methods like `can_update?(resource)`
    # Exactly which methods get defined is determined from `config.abilities`;
    # the module is evaluated after any user-supplied config block is run
    # in order to make that possible.
    # All delegate to corresponding methods on the resource.

    Authority.verbs.each do |verb|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def can_#{verb}?(resource)
          resource.#{Authority.abilities[verb]}_by?(self)
        end
      RUBY
    end

  end
end
