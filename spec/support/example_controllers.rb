module MockController
  def rescue_from(*args) ; end
  def before_filter(*args) ; end
end

# this controller will have `authority_actions_for` called on it
class ExampleController
  extend MockController
  include Authority::Controller
end

# this controller will not have `authority_actions_for` called on it but will
# have `authority_action_for` called on it
class SampleController
  extend MockController
end
