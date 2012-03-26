# Authority

Authority gives you a clean and easy way to say, in your Rails app, **who** is allowed to do **what** with your models. Unauthorized actions get a warning and an entry in a log file.

It requires that you already have some kind of user object in your application, accessible from all controllers (like `current_user`).

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
      <li><a href="#custom_authorizers">Custom Authorizers</a></li>
      <li><a href="#default_strategies">Default strategies</a></li>
      <li><a href="#testing_authorizers">Testing Authorizers</a></li>
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

Authority encapsulates all authorization logic in `Authorizer` classes. Want to do something with a model? Ask its authorizer.

The process generally flows like this:

- In a controller or view, a user object is asked whether it can do some action to a resource class or instance, like `current_user.can_create?(Widget)` or `current_user.can_update?(@widget)`.
- The user just asks the model the same question: `resource.creatable_by?(self)`.
- The model passes that question to its Authorizer, which actually contains the logic to answer the question.
- The Authorizer returns an answer back up the call chain to the original caller.
- If the answer is "no" and the original caller was a controller, this is treated as a `SecurityTransgression`. If it was a view, maybe you just don't show a link.

<a name="installation">
## Installation

Starting from a clean commit status, add `authority` to your Gemfile, `bundle`, then `rails g authority:install`.

<a name="defining_your_abilities">
## Defining Your Abilities

Edit `config/initializers/authority.rb`. That file documents all your options, but one of particular interest is `config.abilities`, which defines the verbs and corresponding adjectives in your app. The defaults are:

    config.abilities =  {
      :create => 'creatable',
      :read   => 'readable',
      :update => 'updatable',
      :delete => 'deletable'
    }

This option determines what methods are added to your users, models and authorizers. If you need to ask `user.can_deactivate?(Satellite)` and `@satellite.deactivatable_by?(user)`, add those to the hash.

<a name="wiring_it_together">
## Wiring It Together

<a name="users">
### Users
In whatever class represents a logged-in user in your application, `include Authority::UserAbilities`.

<a name="models">
### Models
 
In every model, `include Authority::Abilities`. Give every model an [Authorizer](#authorizers). By default, the `Llama` model will look for a `LlamaAuthorizer`. To specify a different one, call `authorizer_name UngulateAuthorizer`; this way, the `UngulateAuthorizer` could also protect the `Zebra` and `Antelope` models, or the `AdminAuthorizer` could protect business-critical models.

<a name="authorizers">
### Authorizers

Add your authorizers under `app/authorizers`, subclassing `Authority::Authorizer` or your own authorizer class. (See `rails g authority::authorizers --help`.)

These are where your actual authorization logic goes. Here's how it works:

- Instance methods answer questions about model instances, like "can this user update this **particular** widget?" (Within an instance method, you can get the model instance with `resource`).
  - Any instance method you don't define (for example, if you didn't make a `def deletable_by?(user)`) will fall back to the corresponding class method. In other words, if you haven't said whether a user can update **this particular** widget, we'll decide by checking whether they can update **any** widget.
- Class methods answer questions about model classes, like "is it **ever** permissible for this user to update a Widget?"
  - Any class method you don't define (for example, if you didn't make a `def self.updatable_by?(user)`) will fall back to your [configurable default strategy](#default_strategies).

For example:

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

As you can see, you can specify different logic for every method on every model, if necessary. On the other extreme, you could simply supply a [default strategy](#default_strategies) that covers all your use cases.

#### Custom Authorizers

If you want to customize your authorizers even further - for example, maybe you want them all to have a method like `has_permission?(user, permission_name)` - you can insert a custom class into the inheritance chain.

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

If you decide to place your custom class in `lib` as shown above (as opposed to putting it in `app`), you should require it at the bottom of `config/initializers/authority.rb`.

<a name="default_strategies">
#### Default Strategies

Any class method you don't define on an authorizer will use your default strategy. The **default** default strategy simply returns false, meaning that everything is forbidden. This whitelisting approach will keep you from accidentally allowing things you didn't intend. 

You can configure a different default strategy. For example, you might want one that looks up permissions in your database:

    # In config/initializers/authority.rb
    config.default_strategy = Proc.new { |able, authorizer, user|
      # Does the user have any of the roles which give this permission?
      (roles_which_grant(able, authorizer) & user.roles).any?
    }

<a name="testing_authorizers">
#### Testing Authorizers

One nice thing about putting your authorization logic in authorizers is the ease of testing. Here's a brief example.

    # An authorizer shared by several admin-only models
    describe AdminAuthorizer do

      before :each do 
        @user  = Factory.build(:user)
        @admin = Factory.build(:admin)
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

<a name="controllers">
### Controllers

Controllers get two ways to check permissions.

- `authorize_actions_for Transaction` protects multiple controller actions with a `before_filter`, which performs a class-level check. If the current user is never allowed to delete a `Transaction`, they'll never even get to the controller's `destroy` method.
- `authorize_action_for @transaction` can be called inside a single controller action, and performs an instance-level check. If called inside `update`, it will check whether the current user is allowed to update this particular `@transaction` instance.

The relationship between controller actions and abilities - like checking `readable_by?` on the `index` action - is configurable both globally, using `config.controller_action_map`, and per controller, as below.

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
        authorize_action_for(@llama)        # failure == SecurityTransgression
        if @llama.save?
        # etc
      end

    end

<a name="views">
### Views

Assuming your user object is available in your views, you can do all kinds of conditional rendering. For example:

    link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_update?(@widget)

If the user isn't allowed to edit widgets, they won't see the link. If they're nosy and try to hit the URL directly, they'll get a [Security Violation](#security_violations_and_logging).

<a name="security_violations_and_logging">
## Security Violations & Logging

Anytime a user attempts an unauthorized action, Authority does two things:

- Renders your `public/403.html`
- Logs the violation to whatever logger you configured.

If you want to have nice log messages for security violations, you should ensure that your user object and models have `to_s` methods; this will control how they show up in log messages saying things like 

    "Kenneth Lay is not allowed to delete this resource: 'accounting_tricks.doc'"

If you feel like setting up a `cron` job to watch the log file, look up the user's name and address, and dispatch minions to fill their mailbox with goose droppings, that's really up to you. I got nothing to do with it, man.

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

1. Fork this project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. `bundle install` to get all dependencies
4. `rspec spec` to run all tests.
5. Update/add tests for your changes and code until they pass.
6. Commit your changes (`git commit -am 'Added some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Pull Request
