# Authority

Authority helps you authorize actions in your Ruby app. It's **ORM-neutral** and has very little fancy syntax; just group your models under one or more Authorizer classes and write plain Ruby methods on them.

Authority will work fine with a standalone app or a single sign-on system. You can check roles in a database or permissions in a YAML file. It doesn't care! What it **does** do is give you an easy way to organize your logic and handle unauthorized actions.

If you're using it with Rails controllers, it requires that you already have some kind of user object in your application, accessible via a method like `current_user` (configurable).

[![Gem Version](https://badge.fury.io/rb/authority.png)](https://rubygems.org/gems/searchlight)
[![Build Status](https://secure.travis-ci.org/nathanl/authority.png?branch=master)](http://travis-ci.org/nathanl/authority)
[![Code Climate](https://codeclimate.com/github/nathanl/authority.png)](https://codeclimate.com/github/nathanl/authority)
[![Dependency Status](https://gemnasium.com/nathanl/authority.png)](https://gemnasium.com/nathanl/authority)

## Contents

<ul>
  <li><a href="#overview">Overview</a></li>
  <li><a href="#flow_of_authority">The flow of Authority</a></li>
  <li><a href="#installation">Installation</a></li>
  <li><a href="#defining_your_abilities">Defining Your Abilities</a></li>
  <li><a href="#wiring_it_together">Wiring It Together</a>
  <ul>
    <li><a href="#users">Users</a></li>
    <li><a href="#models">Models</a></li>
    <li><a href="#authorizers">Authorizers</a>
    <ul>
      <li><a href="#passing_options">Passing Options</a></li>
      <li><a href="#default_methods">Default methods</a></li>
      <li><a href="#testing_authorizers">Testing Authorizers</a></li>
    </ul></li>
    <li><a href="#controllers">Controllers</a></li>
    <li><a href="#views">Views</a></li>
  </ul></li>
  <li><a href="#the_generic_can">The Generic `can?`</a>
  <li><a href="#security_violations_and_logging">Security Violations &amp; Logging</a></li>
  <li><a href="#credits">Credits</a></li>
  <li><a href="#contributing">Contributing</a></li>
</ul>

<a name="overview">
## Overview

Using Authority, you have:

- Broad, **class-level** rules. Examples:
  - "Basic users cannot delete any Widget."
  - "Only admin users can create Offices."
- Fine-grained, **instance-level** rules. Examples:
  - "Management users can only edit schedules with date ranges in the future."
  - "Users can't create playlists more than 20 songs long unless they've paid."
- A clear syntax for permissions-based views. Examples:
  - `link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_update?(@widget)`
  - `link_to 'Keelhaul Scallywag', keelhaul_scallywag_path(@scallywag) if current_user.can_keelhaul?(@scallywag)`
- Graceful handling of access violations: by default, it displays a "you can't do that" screen and logs the violation.
- Minimal effort and mess.

Most importantly, you have **total flexibility**: Authority does not constrain you into using a particular scheme of roles and/or permissions.

Authority lets you control access based on:

- Roles in your app's database ([rolify](http://github.com/EppO/rolify) makes this easy)
- Roles in a separate, single-sign-on app
- Users' points (like StackOverflow)
- Time and date
- Weather, stock prices, vowels in the user's name, or **anything else you can check with Ruby**

All you have to do is define the methods you need on your authorizers. You have all the flexibility of normal Ruby classes.

**You** make the rules; Authority enforces them.

<a name="flow_of_authority">
## The flow of Authority

Authority encapsulates all authorization logic in `Authorizer` classes. Want to do something with a model? **Ask its authorizer**.

You can specify a model's authorizer one of two ways:

- specify the class itself: `authorizer = SomeAuthorizer`
- specify the class's name: `authorizer_name = 'SomeAuthorizer'` (useful if the constant isn't yet loaded)

If you don't specify an authorizer, the model will:

- Look for an authorizer with its name. Eg, `Comment` will look for `CommentAuthorizer`.
- If that's not found, it will use `ApplicationAuthorizer`.

**Models that have the same authorization rules should use the same authorizer**. In other words, if you would write the exact same methods on two models to determine who can create them, who can edit them, etc, then they should use the same authorizer.

Some example groupings:

         Simplest case                Logical groups                                 Most granular

      ApplicationAuthorizer        ApplicationAuthorizer                         ApplicationAuthorizer
               +                             +                                             +
               |                    +--------+-------+                 +-------------------+-------------------+
               |                    +                +                 +                   +                   +
               |             BasicAuthorizer   AdminAuthorizer  CommentAuthorizer  ArticleAuthorizer  EditionAuthorizer
               |                    +                +                 +                   +                   +
       +-------+-------+            +-+       +------+                 |                   |                   |
       +       +       +              +       +      +                 +                   +                   +
    Comment Article Edition        Comment Article Edition          Comment             Article             Edition

The authorization process generally flows like this:

                   current_user.can_create?(Article)                 # You ask this question, and the user
                               +                                     # automatically asks the model...
                               |
                               v
                 Article.creatable_by?(current_user)                 # The model automatically asks
                               +                                     # its authorizer...
                               |
                               v
               AdminAuthorizer.creatable_by?(current_user)           # *You define this method.*
                               +                                     # If you don't, the inherited one
                               |                                     # calls `default`...
                               v
        AdminAuthorizer.default(:creatable, current_user)            # *You define this method.*
                                                                     # If you don't, it will use the one
                                                                     # inherited from ApplicationAuthorizer.
                                                                     # (Its parent, Authority::Authorizer,
                                                                     # defines the method as `return false`.)

If the answer is `false` and the original caller was a controller, this is treated as a `SecurityViolation`. If it was a view, maybe you just don't show a link.

(Diagrams made with [AsciiFlow](http://asciiflow.com))

<a name="installation">
## Installation

Starting from a clean commit status, add `authority` to your Gemfile, then `bundle`.

If you're using Rails, run `rails g authority:install`. Otherwise, pass a block to `Authority.configure` with [configuration options](https://github.com/nathanl/authority/blob/master/lib/generators/templates/authority_initializer.rb) somewhere when your application boots up.

<a name="defining_your_abilities">
## Defining Your Abilities

Edit `config/initializers/authority.rb`. That file documents all your options, but one of particular interest is `config.abilities`, which defines the verbs and corresponding adjectives in your app. The defaults are:

```ruby
config.abilities =  {
  :create => 'creatable',
  :read   => 'readable',
  :update => 'updatable',
  :delete => 'deletable'
}
```

This option determines what methods are added to your users, models and authorizers. If you need to ask `user.can_deactivate?(Satellite)` and `@satellite.deactivatable_by?(user)`, add `:deactivate => 'deactivatable'` to the hash.

<a name="wiring_it_together">
## Wiring It Together

<a name="users">
### Users

```ruby
# Whatever class represents a logged-in user in your app
class User
  # Adds `can_create?(resource)`, etc
  include Authority::UserAbilities
...
end
```

<a name="models">
### Models

```ruby
class Article
  # Adds `creatable_by?(user)`, etc
  include Authority::Abilities

  # Without this, 'ApplicationAuthorizer' is assumed
  self.authorizer_name = 'AdminAuthorizer'
  ...
end
```

<a name="authorizers">
### Authorizers

Add your authorizers under `app/authorizers`, subclassing the generated `ApplicationAuthorizer`.

These are where your actual authorization logic goes. Here's how it works:

- Instance methods answer questions about model instances, like "can this user update this **particular** widget?" (Within an instance method, you can get the model instance with `resource`).
  - Any instance method you don't define (for example, if you didn't make a `def deletable_by?(user)`) will fall back to the corresponding class method. In other words, if you haven't said whether a user can update **this particular** widget, we'll decide by checking whether they can update **any** widget.
- Class methods answer questions about model classes, like "is it **ever** permissible for this user to update a Widget?"
  - Any class method you don't define (for example, if you didn't make a `def self.updatable_by?(user)`) will call that authorizer's `default` method.

For example:

```ruby
# app/authorizers/schedule_authorizer.rb
class ScheduleAuthorizer < ApplicationAuthorizer
  # Class method: can this user at least sometimes create a Schedule?
  def self.creatable_by?(user)
    user.manager?
  end

  # Instance method: can this user delete this particular schedule?
  def deletable_by?(user)
    resource.in_future? && user.manager? && resource.department == user.department
  end
end

# undefined; calls `ScheduleAuthorizer.default(:updatable, user)`
ScheduleAuthorizer.updatable_by?(user)
```

As you can see, you can specify different logic for every method on every model, if necessary. On the other extreme, you could simply supply a [default method](#default_methods) that covers all your use cases.

<a name="passing_options">
#### Passing Options

Any options you pass when checking permissions will be passed right up the chain. One use case for this would be if you needed an associated instance in order to do a class-level check. For example:

```ruby
# I don't have a comment instance to check, but I need to know
# which post the user wants to comment on
user.can_create?(Comment, :for => @post)
```

This would ultimately call `creatable_by?` on the designated authorizer with two arguments: the user and `{:for => @post}`. If you've defined that method yourself, you'd need to ensure that it accepts the options hash before doing this, or you'd get a "wrong number of arguments" error.

There's nothing special about the hash key `:for`; I just think it reads well in this case. You can pass any options that make sense in your case.

If you **don't** pass options, none will be passed to your authorizer, either.

And you could always handle the case above without options if you don't mind creating an extra model instance:

```ruby
user.can_create?(Comment.new(:post => @post))
```

<a name="default_methods">
#### Default Methods

Any class method you don't define on an authorizer will call the `default` method on that authorizer. This method is defined on `Authority::Authorizer` to simply return false. This is a 'whitelisting' approach; any permission you haven't specified (which falls back to the default method) is considered forbidden.

You can override this method in your `ApplicationAuthorizer` and/or per authorizer. For example, you might want one that looks up the user's roles and correlates them with permissions:

```ruby
# app/authorizers/application_authorizer.rb
class ApplicationAuthorizer < Authority::Authorizer

  # Example call: `default(:creatable, current_user)`
  def self.default(able, user)
    has_role_granting?(user, able) || user.admin?
  end

  protected

  def has_role_granting?(user, able)
    # Does the user have any of the roles which give this permission?
    (roles_which_grant(able) & user.roles).any?
  end

  def roles_which_grant(able)
    # Look up roles for the current authorizer and `able`
    ...
  end
end
```

If your system is uniform enough, **this method alone might handle all the logic you need**.

<a name="testing_authorizers">
#### Testing Authorizers

One nice thing about putting your authorization logic in authorizers is the ease of testing. Here's a brief example.

```ruby
# An authorizer shared by several admin-only models
describe AdminAuthorizer do

  before :each do
    @user  = FactoryGirl.build(:user)
    @admin = FactoryGirl.build(:admin)
  end

  describe "class" do
    it "lets admins update in bulk" do
      expect(AdminAuthorizer).to be_bulk_updatable_by(@admin)
    end

    it "doesn't let users update in bulk" do
      expect(AdminAuthorizer).not_to be_bulk_updatable_by(@user)
    end
  end

  describe "instances" do

    before :each do
      # A mock model that uses AdminAuthorizer
      @admin_resource_instance = mock_admin_resource
    end

    it "lets admins delete" do
      expect(@admin_resource_instance.authorizer).to be_deletable_by(@admin)
    end

    it "doesn't let users delete" do
      expect(@admin_resource_instance.authorizer).not_to be_deletable_by(@user)
    end

  end

end
```

<a name="controllers">
### Controllers

If you're using Rails, ActionController support will be loaded in through a Railtie. Otherwise, you'll want to integrate it into your framework yourself. [Authority's controller](https://github.com/nathanl/authority/blob/master/lib/authority/controller.rb) is an excellent starting point.

Anytime a controller finds a user attempting something they're not authorized to do, a [Security Violation](#security_violations_and_logging) will result. Controllers get two ways to check authorization:

- `authorize_actions_for Llama` protects multiple controller actions with a `before_filter`, which performs a **class-level** check. If the current user is never allowed to delete a `Llama`, they'll never even get to the controller's `destroy` method.
- `authorize_action_for @llama` can be called inside a single controller action, and performs an **instance-level** check. If called inside `update`, it will check whether the current user is allowed to update this particular `@llama` instance.

How does Authority know to check `deletable_by?` before the controller's `destroy` action? It checks your configuration. These mappings are configurable globally from the initializer file. Defaults are as follows:

```ruby
config.controller_action_map = {
 :index   => 'read',    # `index` controller action will check `readable_by?`
 :show    => 'read',
 :new     => 'create',  # `new` controller action will check `creatable_by?`
 :create  => 'create',  # ...etc
 :edit    => 'update',
 :update  => 'update',
 :destroy => 'delete'
}
```

They are also configurable per controller, as follows:

```ruby
class LlamasController < ApplicationController

  # Check class-level authorizations before all actions except :create
  # Also, to authorize this controller's 'neuter' action, ask whether `current_user.can_update?(Llama)`
  authorize_actions_for Llama, :except => :create, :actions => {:neuter => :update},

  # To authorize this controller's 'breed' action, ask whether `current_user.can_create?(Llama)`
  # To authorize its 'vaporize' action, ask whether `current_user.can_delete?(Llama)`
  authority_actions :breed => 'create', :vaporize => 'delete'

  ...

  def edit
    @llama = Llama.find(params[:id])
    authorize_action_for(@llama)        # Check to see if you're allowed to edit this llama. failure == SecurityViolation
  end

  def update
    @llama = Llama.find(params[:id])
    authorize_action_for(@llama)        # Check to see if you're allowed to edit this llama.
    @llama.attributes = params[:llama]  # Don't save the attributes before authorizing
    authorize_action_for(@llama)        # Check again, to see if the changes are allowed.
    if @llama.save?
    # etc
  end

end
```

As with other authorization checks, you can also pass options here, and they'll be sent along to your authorization method: `authorize_action_for(@llama, :sporting => @hat_style)`. Generally, though, your authorization will depend on some attribute or association of the model instance, so the authorizer can check `@llama.neck_strength` and `@llama.owner.nationality`, etc, without needing any additional information.

Note that you can also call `authority_actions` as many times as you like, so you can specify one mapping at a time if you prefer:

```ruby
class LlamasController < ApplicationController
  def breed
    # some code
  end
  authority_actions :breed => 'create'

  def vaporize
    # some code
  end
  authority_actions :vaporize => 'delete'
end
```

If you have a controller that dynamically determines the class it's working with, you can pass the name of a controller instance method to `authorize_actions_for` instead of a class, and the class will be looked up when a request is made.

```ruby
class LlamasController < ApplicationController

  authorize_actions_for :llama_class

  def llama_class
    # This method can simply return a class...
    [StandardLlama, LludicrousLlama].sample

    # ... or an array with a class and some options
    [OptionLladenLlama, {country: 'Peru'}]
  end
end
```

If you want to authorize all actions the same way, use the special `all_actions` hash key. For instance, if you have nested resources, you might say "you're allowed to do anything you like with an employee if you're allowed to update their organization".

```ruby
class EmployeesController < ApplicationController
  authorize_actions_for :parent_resource, all_actions: :update
  private
  def parent_resource
    Employer.find(params[:employer_id])
  end
end
```

Finally, you can enforce that every controller action runs an authorization check using the class method `ensure_authorization_performed`, which sets up an `after_filter` to raise an exception if it wasn't. Any `only` or `except` arguments will be passed to `after_filter`. You can also use `if` or `unless` to specify the name of a controller method which determines whether it's necessary.

Since this runs in an `after_filter`, it obviously doesn't prevent the action, it just alerts you that no authorization was performed. Therefore, it's most useful in development. An example usage might be:

```ruby
class ApplicationController < ActionController::Base
  ensure_authorization_performed :except => [:index, :search], :if => :auditing_security?, :unless => :devise_controller?

  def auditing_security?
    Rails.env != 'production'
  end
end
```

If you want a skippable filter, you can roll your own using the instance method, also called `ensure_authorization_performed`.

<a name="views">
### Views

Assuming your user object is available in your views, you can do all kinds of conditional rendering. For example:

```ruby
link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_update?(@widget)
```

If the user isn't allowed to edit widgets, they won't see the link. If they're nosy and try to hit the URL directly, they'll get a [Security Violation](#security_violations_and_logging) from the controller.

<a name="the_generic_can">
## The Generic `can?`

Authority is organized around protecting resources. But **occasionally** you **may** need to authorize something that has no particular resource. For that, it provides the generic `can?` method. It works like this:

```ruby
current_user.can?(:view_stats_dashboard) # calls `ApplicationAuthorizer.authorizes_to_view_stats_dashboard?`
current_user.can?(:view_stats_dashboard, :on => :tuesdays, :with => :tea) # same, passing the options

# application_authorizer.rb
class ApplicationAuthorizer < Authority::Authorizer
  # ...
  def self.authorizes_to_view_stats_dashboard?(user, options = {})
    user.has_role?(:manager) # or whatever
  end
end
```

Use this very sparingly, and consider it a [code smell](http://en.wikipedia.org/wiki/Code_smell). Overuse will turn your `ApplicationAuthorizer` into a junk drawer of methods. Ask yourself, "am I sure I don't have a resource for this? Should I have one?"

<a name="security_violations_and_logging">
## Security Violations & Logging

If you're using Authority's `ActiveController` integration or have used it as a template for your own, your application will handle unauthorized requests with `403 Forbidden` automatically.

If you use Authority to [conditionally render links](#security_violations_and_logging), users will only see links for actions they're authorized to take. If a user deliberately tries to access a restricted resource (for instance, by typing the URL directly), Authority raises and rescues an `Authority::SecurityViolation`.

When it rescues the exception, Authority calls whatever controller method is specified by your `security_violation_handler` option, handing it the exception. The default handler is `authority_forbidden`, which Authority mixes in to your `ApplicationController`. It does the following:

- Renders `public/403.html`
- Logs the violation to whatever logger you configured.

You can define your own `authority_forbidden` method on `ApplicationController` and/or any other controller. For example:

```ruby
# Send 'em back where they came from with a slap on the wrist
def authority_forbidden(error)
  Authority.logger.warn(error.message)
  redirect_to request.referrer.presence || root_path, :alert => 'You are not authorized to complete that action.'
end
```

Your method will be handed the `SecurityViolation`, which has a `message` method. In case you want to build your own message, it also exposes `user`, `action` and `resource`.

<a name="credits">
## Credits, AKA 'Shout-Outs'

- [adamhunter](https://github.com/adamhunter) for pairing with me on this gem. The only thing faster than his typing is his brain.
- [kevmoo](https://github.com/kevmoo), [MP211](https://github.com/MP211), and [scottmartin](https://github.com/scottmartin) for pitching in.
- [nkallen](https://github.com/nkallen) for writing [a lovely blog post on access control](http://pivotallabs.com/users/nick/blog/articles/272-access-control-permissions-in-rails) when he worked at Pivotal Labs. I cried sweet tears of joy when I read that a couple of years ago. I was like, "Zee access code, she is so BEEUTY-FUL!"
- [jnunemaker](https://github.com/jnunemaker) for later creating [Canable](http://github.com/jnunemaker/canable), another inspiration for Authority.
- [TMA](http://www.tma1.com) for employing me and letting me open source some of our code.

<a name="contributing">

## Responses, AKA 'Hollaback'

Do you like Authority? Has it cleaned up your code, made you more personable, and taught you the Secret to True Happiness? Awesome! I'd **love** to get email from you - see my Github profile for the address.

## Contributing

How can you contribute? Let me count the ways.

### 1. Publicity

If you like Authority, tell people! Blog, tweet, comment, or even... [shudder]... talk with people *in person*. If you feel up to it, I mean. It's OK if you don't.

### 2. Documentation

Add examples to the [wiki](http://github.com/nathanl/authority/wiki) to help others solve problems like yours.

### 3. Issues

Tell me your problems and/or ideas.

### 4. Code or documentation

1. Have an idea. If you don't have one, check the TODO file or grep the project for 'TODO' comments.
2. Open an issue so we can talk it over.
3. Fork this project
4. Create your feature branch (`git checkout -b my-new-feature`)
5. `bundle install` to get all dependencies
6. `rspec spec` to run all tests.
7. Update/add tests for your changes and code until they pass.
8. Commit your changes (`git commit -am 'Added some feature'`)
9. Push to the branch (`git push origin my-new-feature`)
10. Create a new Pull Request
