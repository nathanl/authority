# Authority

Authority helps you authorize actions in your Rails app. It's **ORM-neutral** and has very little fancy syntax; just group your models under one or more Authorizer classes and write plain Ruby methods on them.

Authority will work fine with a standalone app or a single sign-on system. You can check roles in a database or permissions in a YAML file. It doesn't care! What it **does** do is give you an easy way to organize your logic, define a default strategy, and handle unauthorized actions.

It requires that you already have some kind of user object in your application, accessible from all controllers and views via a method like `current_user` (configurable).

[![Build Status](https://secure.travis-ci.org/nathanl/authority.png)](http://travis-ci.org/nathanl/authority)

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
      <li><a href="#default_strategies">Default strategies</a></li>
      <li><a href="#testing_authorizers">Testing Authorizers</a></li>
      <li><a href="#custom_authorizers">Custom Authorizers</a></li>
    </ul></li>
    <li><a href="#controllers">Controllers</a></li>
    <li><a href="#views">Views</a></li>
  </ul></li>
  <li><a href="#security_violations_and_logging">Security Violations &amp; Logging</a></li>
  <li><a href="#credits">Credits</a></li>
  <li><a href="#contributing">Contributing</a></li>
</ul>

<a name="overview">
## Overview

The goals of Authority are:

- To allow broad, class-level rules. Examples: 
  - "Basic users cannot delete any Widget."
  - "Only admin users can create Offices."
- To allow fine-grained, instance-level rules. Examples: 
  - "Management users can only edit schedules with date ranges in the future."
  - "Users can't create playlists more than 20 songs long unless they've paid."
- To provide a clear syntax for permissions-based views. Example:
  - `link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_update?(@widget)`
- To gracefully handle any access violations: display a "you can't do that" screen and log the violation.
- To do all this with minimal effort and mess.

<a name="flow_of_authority">
## The flow of Authority

Authority encapsulates all authorization logic in `Authorizer` classes. Want to do something with a model? **Ask its authorizer**.

You can group models under authorizers in any way you wish. For example:


        +-------------+              +--------------+                               +-------------+
        |Simplest case|              |Logical groups|                               |Most granular|
        +-------------+              +--------------+                               +-------------+

        default_strategy              default_strategy                              default_strategy
               +                             +                                             +
               |                    +--------+-------+                 +-------------------+-------------------+
               +                    +                +                 +                   +                   +
       EverythingAuthorizer  BasicAuthorizer   AdminAuthorizer  CommentAuthorizer  ArticleAuthorizer  EditionAuthorizer
               +                    +                +                 +                   +                   +
       +-------+-------+            +-+       +------+                 |                   |                   |
       +       +       +              +       +      +                 +                   +                   +
    Comment Article Edition        Comment Article Edition          Comment             Article             Edition


The process generally flows like this:

                   current_user.can_create?(Moose)                   # You ask this question, and the user
                               +                                     # automatically asks the model...
                               |
                               v
                   Moose.creatable_by?(current_user)                 # The model automatically asks
                               +                                     # its authorizer...
                               |
                               v
               MooseAuthorizer.creatable_by?(current_user)           # *You define this method.*
                               +                                     # If it's missing, the default
                               |                                     # strategy is used...
                               v
    config.default_strategy.call(:creatable, MooseAuthorizer, user)  # *You define this strategy.*

If the answer is `false` and the original caller was a controller, this is treated as a `SecurityViolation`. If it was a view, maybe you just don't show a link.

(Diagrams made with [AsciiFlow](http://asciiflow.com))

<a name="installation">
## Installation

Starting from a clean commit status, add `authority` to your Gemfile, `bundle`, then `rails g authority:install`.

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

This option determines what methods are added to your users, models and authorizers. If you need to ask `user.can_deactivate?(Satellite)` and `@satellite.deactivatable_by?(user)`, add those to the hash.

<a name="wiring_it_together">
## Wiring It Together

<a name="users">
### Users

```ruby
# Whatever class represents a logged-in user in your app
class User 
  # Adds `can_create?(resource)`, etc
  include Authority::Abilities
...
end
```

<a name="models">
### Models

```ruby
class Article
  # Adds `creatable_by?(user)`, etc
  include Authority::Abilities

  # Without this, ArticleAuthorizer is assumed
  self.authorizer_name = 'AdminAuthorizer'
  ...
end
```

<a name="authorizers">
### Authorizers

Add your authorizers under `app/authorizers`, subclassing `Authority::Authorizer`.

These are where your actual authorization logic goes. Here's how it works:

- Instance methods answer questions about model instances, like "can this user update this **particular** widget?" (Within an instance method, you can get the model instance with `resource`).
  - Any instance method you don't define (for example, if you didn't make a `def deletable_by?(user)`) will fall back to the corresponding class method. In other words, if you haven't said whether a user can update **this particular** widget, we'll decide by checking whether they can update **any** widget.
- Class methods answer questions about model classes, like "is it **ever** permissible for this user to update a Widget?"
  - Any class method you don't define (for example, if you didn't make a `def self.updatable_by?(user)`) will fall back to your configurable [default strategy](#default_strategies).

For example:

```ruby
# app/authorizers/schedule_authorizer.rb
class ScheduleAuthorizer < Authority::Authorizer
  # Class method: can this user at least sometimes create a Schedule?
  def self.creatable_by?(user)
    user.manager?
  end

  # Instance method: can this user delete this particular schedule?
  def deletable_by?(user)
    resource.in_future? && user.manager? && resource.department == user.department
  end
end
```

As you can see, you can specify different logic for every method on every model, if necessary. On the other extreme, you could simply supply a [default strategy](#default_strategies) that covers all your use cases.

<a name="default_strategies">
#### Default Strategies

Any class method you don't define on an authorizer will use your default strategy. The **default** default strategy simply returns `false`, meaning that everything is forbidden. This whitelisting approach will keep you from accidentally allowing things you didn't intend. 

You can configure a different default strategy. For example, you might want one that looks up permissions in your database:

```ruby
# In config/initializers/authority.rb
config.default_strategy = Proc.new do |able, authorizer, user|
  # Does the user have any of the roles which give this permission?
  (roles_which_grant(able, authorizer) & user.roles).any?
end
```

If your system is uniform enough, **this strategy alone might handle all the logic you need**.

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
    it "should let admins update in bulk" do
      AdminAuthorizer.should be_bulk_updatable_by(@admin)
    end

    it "should not let users update in bulk" do
      AdminAuthorizer.should_not be_bulk_updatable_by(@user)
    end
  end

  describe "instances" do

    before :each do
      # A mock model that uses AdminAuthorizer
      @admin_resource_instance = mock_admin_resource
    end

    it "should not allow users to delete" do
      @admin_resource_instance.authorizer.should_not be_deletable_by(@user)
    end

  end

end
```

<a name="custom_authorizers">
#### Custom Authorizers

If you want to customize your authorizers even further - for example, maybe you want them all to have a method like `has_permission?(user, permission_name)` - you can insert a custom class into the inheritance chain.

```ruby
# lib/my_app/authorizer.rb
module MyApp
  class Authorizer < Authority::Authorizer
  
    def self.has_permission(user, permission_name)
      # look that up somewhere
    end

  end
end

#app/authorizers/badger_authorizer.rb
class BadgerAuthorizer < MyApp::Authorizer
  # contents
end
```

If you decide to place your custom class in `lib` as shown above (as opposed to putting it in `app`), you should require it at the bottom of `config/initializers/authority.rb`.

<a name="controllers">
### Controllers

Anytime a controller finds a user attempting something they're not authorized to do, a [Security Violation](#security_violations_and_logging) will result. Controllers get two ways to check authorization:

- `authorize_actions_for Transaction` protects multiple controller actions with a `before_filter`, which performs a class-level check. If the current user is never allowed to delete a `Transaction`, they'll never even get to the controller's `destroy` method.
- `authorize_action_for @transaction` can be called inside a single controller action, and performs an instance-level check. If called inside `update`, it will check whether the current user is allowed to update this particular `@transaction` instance.

The relationship between controller actions and abilities - like checking `readable_by?` on the `index` action - is configurable both globally, using `config.controller_action_map`, and per controller, as below.

```ruby
class LlamaController < ApplicationController

  # Check class-level authorizations before all actions except :create
  # Before this controller's 'neuter' action, ask whether current_user.can_update?(Llama)
  authorize_actions_for Llama, :actions => {:neuter => :update}, :except => :create
  
  # Before this controller's 'breed' action, ask whether current_user.can_create?(Llama)
  authority_action :breed => 'new'

  ...

  def edit
    @llama = Llama.find(params[:id])
    @llama.attributes = params[:llama]  # Don't save the attributes before authorizing
    authorize_action_for(@llama)        # failure == SecurityViolation
    if @llama.save?
    # etc
  end

end
```

<a name="views">
### Views

Assuming your user object is available in your views, you can do all kinds of conditional rendering. For example:

```ruby
link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_update?(@widget)
```

If the user isn't allowed to edit widgets, they won't see the link. If they're nosy and try to hit the URL directly, they'll get a [Security Violation](#security_violations_and_logging) from the controller.

<a name="security_violations_and_logging">
## Security Violations & Logging

Anytime a user attempts an unauthorized action, Authority calls whatever controller method is specified by your `security_violation_handler` option, handing it the exception. The default handler is `authority_forbidden`, which Authority adds to your `ApplicationController`. It does the following:

- Renders `public/403.html`
- Logs the violation to whatever logger you configured.

You can specify a different handler like so:

```ruby
# config/initializers/authority.rb
...
config.security_violation_handler = :fire_ze_missiles
...

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base

  def fire_ze_missiles(exception)
    # Log? Set a flash message? Dispatch minions to 
    # fill their mailbox with goose droppings? It's up to you.
  end
...
end
```

If you want different error handling per controller, define `fire_ze_missiles` on each of them.

<a name="credits">
## Credits, AKA 'Shout-Outs'

- [adamhunter](https://github.com/adamhunter) for pairing with me on this gem. The only thing faster than his typing is his brain.
- [nkallen](https://github.com/nkallen) for writing [a lovely blog post on access control](http://pivotallabs.com/users/nick/blog/articles/272-access-control-permissions-in-rails) when he worked at Pivotal Labs. I cried sweet tears of joy when I read that a couple of years ago. I was like, "Zee access code, she is so BEEUTY-FUL!"
- [jnunemaker](https://github.com/jnunemaker) for later creating [Canable](http://github.com/jnunemaker/canable), another inspiration for Authority.
- [TMA](http://www.tma1.com) for employing me and letting me open source some of our code.

<a name="contributing">
## Contributing

What should you contribute? Try the TODO file for ideas, or grep the project for 'TODO' comments.

How can you contribute?

1. Let's talk! Before you do a bunch of work, open an issue so we can be sure we agree.
2. Fork this project
3. Create your feature branch (`git checkout -b my-new-feature`)
4. `bundle install` to get all dependencies
5. `rspec spec` to run all tests.
6. Update/add tests for your changes and code until they pass.
7. Commit your changes (`git commit -am 'Added some feature'`)
8. Push to the branch (`git push origin my-new-feature`)
9. Create a new Pull Request
