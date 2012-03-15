# Authority

Authority gives you a clean and easy way to say, in your Rails app, **who** is allowed to do **what** with your models.

It requires that you already have some kind of user object in your application, accessible from all controllers (like `current_user`).

[![Build Status](https://secure.travis-ci.org/nathanl/authority.png)](http://travis-ci.org/nathanl/authority)

## TL;DR

No time for reading! Reading is for chumps! Here's the skinny:

- Install in your Rails project: add to Gemfile, `bundle`, then `rails g authority:install`
- Put this in your controllers: `check_authorization_on YourModelNameHere` (the model that controller works with)
- Put this in your models:  `include Authority::Abilities`
- For each model you have, create a corresponding `YourModelNameHereAuthorizer`. For example, for `app/models/lolcat.rb`, create `app/authorizers/lolcat_authorizer.rb` with an empty class inheriting from `Authority::Authorizer`.
- Add class methods to that authorizer to set rules that can be enforced just by looking at the resource class, like "this user cannot create Lolcats, period."
- Add instance methods to that authorizer to set rules that need to look at a resource instance, like "a user can only edit a Lolcat if it belongs to that user and has not been marked as 'classic'".

## Overview

Still here? Reading is fun! You always knew that. Time for a deeper look at things.

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
- To do all of this **without cluttering** either your controllers or your models. This is done by letting Authorizer classes do most of the work. More on that below.

## The flow of Authority

In broad terms, the authorization process flows like this:

- A user object is asked whether it can do some action to a resource class or instance, like `current_user.can_create?(Widget)` or `current_user.can_update?(@widget)`.
- The user just asks the model the same question: `resource.creatable_by?(self)`.
- The model passes that question to its Authorizer, which actually contains the logic to answer the question.
- The Authorizer returns an answer back up the call chain to the original caller.

## Installation

First, check in whatever changes you've made to your app already. You want to see what we're doing to your app, don't you?

Now, add this line to your application's Gemfile:

    gem 'authority'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authority

Then run the generator:

    $ rails g authority:install

Hooray! New files! Go look at them. Look look look.

## Usage

### Users

Your user model (whatever you call it) should `include Authority::UserAbilities`. This defines methods like `can_update?(resource)`. These methods do nothing but pass the question on to the resource itself. For example, `resource.updatable_by?(user)`.

The list of methods that get defined comes from `config.abilities`.

### Models

In your models, `include Authority::Abilities`. This sets up both class-level and instance-level methods like `creatable_by?(user)`, etc. 

The list of methods that get defined comes from `config.abilities`.

You **could** define those methods yourself on the model, but to keep things organized, we want to put all our authorization logic in authorizer classes. Therefore, these methods, too, are pass-through, which delegate to corresponding methods on the model's authorizer. For example, the `Rabbit` model would delegate to `RabbitAuthorizer`.

Which leads us to...

### Authorizers

Authorizers should be added under `app/authorizers`, one for each of your models. So if you have a `LaserCannon` model, you should have, at minimum:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
      # Nothing defined - just use the default strategy
    end

These are where your actual authorization logic goes. You do have to specify your own business rules, but Authority comes with the following baked in:

- All instance-level methods defined on `Authority::Authorizer` call their corresponding class-level method by default. In other words, if you haven't said whether a user can update **this particular** widget, we'll decide by checking whether they can update **any** widget. (To refer to the resource instance, use `resource`.)
- All class-level methods defined on `Authority::Authorizer` will use the `default_strategy` you define in your configuration (see the notes in the generated `config/initializers/authority.rb`).
- The **default** default strategy simply returns false, so unless you redefine it or write methods in your Authorizer classes, **everything is forbidden**. This whitelisting approach will keep you from accidentally allowing things you didn't intend.

Let's work our way up from the simplest possible authorizer to see how you can customize your rules.

If your authorizer looks like this:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
    end

... you will find that everything is forbidden:

    current_user.can_create?(LaserCannon)    # false; you haven't defined a class-level `can_create?`, so the 
                                             # `default_strategy` is used. It returns false.
    current_user.can_create?(@laser_cannon)  # false; instance-level permissions check class-level ones by default,
                                             # so this is the same as the previous example.

If you update your authorizer as follows:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer

      # Class-level permissions
      #
      def self.creatable_by?(user)
        true # blanket true means that **any** user can create a laser cannon
      end

      def self.deletable_by?(user)
        false # blanket false means that **no** user can delete a laser cannon
      end

      # Instance-level permissions
      #
      def updatable_by?(user)
        resource.color == 'blue' && user.first_name == 'Larry' && Date.today.friday?
      end

    end

... you can now do the following:

    current_user.can_create?(LaserCannon)    # true, per class method above
    current_user.can_create?(@laser_cannon)  # true; inherited instance method calls class method
    current_user.can_delete?(@laser_cannon)  # false
    current_user.can_update?(@laser_cannon)  # Only Larry, only blue laser cannons, and only on 
                                             # Fridays (weapons maintenance day)

### Controllers

#### Basic Usage

In your controllers, add this method call:

`check_authorization_on ModelName`

That sets up a `before_filter` that calls your class-level methods before each action. For instance, before running the `update` action, it will check whether `ModelName` is `updatable_by?` the current user at a class level. A return value of false means "this user can never update models of this class."

If that's all you need, one line does it.

#### In-action usage

If you need to check some attributes of a model instance to decide if an action is permissible, you can use `check_authorization_for(@resource_instance, @user)`. This will check the proper instance method on the authorizer, based on which controller action you're currently in.

The default map from controller actions to authorizations is as follows: 

    {
      :index   => 'read',
      :show    => 'read',
      :new     => 'create',
      :create  => 'create',
      :edit    => 'update',
      :update  => 'update',
      :destroy => 'delete'
    }

Each controller gets its own copy of this hash, which comes from `config.authority_actions`.

If you want to edit a **single** controller's action map, you can either pass a hash into `check_authorization_on`, which will get merged into the existing actions hash...

    class BadgerController < ApplicationController
      check_authorization_on Badger, :actions => {:neuter => 'update'}
      ...
    end

...or you can use a separate method call:

    class BadgerController < ApplicationController
      check_authorization_on Badger

      authority_action :neuter => 'update'

      ...
    end

Finally, if you want to update this hash for **all** your controllers, you can do that with `config.authority_actions` in the initializer.

## Configuration

Configuration should be done from `config/initializers/authority.rb`, which will be generated for you by `rails g authority:install`. That file includes copious documentation. Copious, do you hear me?!

Ahem. Note that the configuration block in that file **must** run in your application. Authority metaprograms its methods on boot, but waits until your configuration block has run to do so. If you want the default settings, you don't have to put anything in your configure block, but you must at least run `Authority.configure`.

Some of the things you can configure which haven't already been mentioned are...

### Abilities

If you want to be able to say `user.can_eat?` and have Authority ask the model and authorizer if the resource is `edible_by?` the user, edit your `config.abilities` to include `{:eat => 'edible'}`.

### Logging

Authority will log a message any time a user tries to access a resource for which they are not authorized. By default, this is logged to standard error, but you can supply whatever logger you want, as long as it responds to `warn`. Some possible settings are:

    config.logger = Rails.logger
    config.logger = Logger.new('logs/authority.log') # From Ruby standard library

## Further customization of authorizers

If you want to customize your authorizers even further - for example, maybe you want them to have a method like `has_permission?(user, permission_name)` - just insert a custom into the inheritance chain.

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

## Integration Notes

- If you want to have nice log messages for security violations, you should ensure that your user object has a `to_s` method; this will control how it shows up in log messages saying things like "**Regina Johnson** is not allowed to delete this resource:..."

## Credits, AKA 'Shout-Outs'

- @adamhunter for pairing with me on this gem. The only thing faster than his typing is his brain.
- @nkallen for [this lovely blog post on access control](http://pivotallabs.com/users/nick/blog/articles/272-access-control-permissions-in-rails) when he worked at Pivotal Labs. I cried sweet tears of joy when I read that article a couple of years ago.
- @jnunemaker for later creating Canable, another inspiration for Authority.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. `bundle install` to get all dependencies
4. `rspec spec` to run all tests.
5. Make your changes and update/add tests as necessary.
6. Commit your changes (`git commit -am 'Added some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create new Pull Request

## TODO

- Add YARD docs everywhere
- Test generators
- Test view helpers
- Make TL;DR examples link to examples further down in README
- Give more thorough example of usage mid controller action.
