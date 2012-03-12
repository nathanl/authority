module Authority
  module UserAbilities

    Authority.verbs.each do |verb|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def can_#{verb}?(resource)
          resource.#{Authority.abilities[verb]}_by?(self)
        end
      RUBY
    end
   
  end
end
