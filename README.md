# Authority

## SUPER BETA VERSION. Stabler release coming soon.

## TL;DR

No time for reading! Reading is for chumps! Here's the skinny:

- Install in your Rails project: `bundle install` and `rake authority:install`
- Put this in your controllers: `check_authorization_on YourModelNameHere` (the model that controller works with)
- Put this in your models:  `include Authority::Abilities`
- For each model you have, create a corresponding `YourModelNameHereAuthorizer`. For example, for `app/models/lolcat.rb`, create `app/authorizers/lolcat_authorizer.rb` with an empty class inheriting from `Authority::Authorizer`.
- Add class methods to that authorizer to set rules that can be enforced just by looking at the resource class, like "this user cannot create Lolcats, period."
- Add instance methods to that authorizer to set rules that need to look at a resource instance, like "a user can only edit a Lolcat if it belongs to that user and has not been marked as 'classic'".

## Overview

Still here? Reading is fun! You always knew that. Time for a deeper look at things.

Authority gives you a clean and easy way to say, in your Rails app, **who** is allowed to do **what** with your models.

It assumes that you already have some kind of user object in your application.

The goals of Authority are:

- To allow broad, class-level rules. Examples: 
  - "Basic users cannot delete **any** Widget."
  - "Only admin users can create Offices."

- To allow fine-grained, instance-level rules. Examples: 
  - "Management users can only edit schedules in their jurisdiction."
  - "Users can't create playlists more than 20 songs long unless they've paid."

- To provide a clear syntax for permissions-based views. Example:
  - `link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_edit?(@widget)`

- To gracefully handle any access violations: display a "you can't do that" screen and log the violation.

- To do all of this **without cluttering** either your controllers or your models. This is done by letting Authorizer classes do most of the work. More on that below.

## The flow of Authority

In broad terms, the authorization process flows like this:

- A request comes to a model, either the class or an instance, saying "can this user do this action to you?"
- The model passes that question to its Authorizer
- The Authorizer checks whatever user properties and business rules are relevant to answer that question.
- The answer is passed back up to the model, then back to the original caller

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

Hooray! New files! Go look at them.

## Usage

### Users

Your user model (whatever you call it) should `include Authority::UserAbilities`. This defines methods like `can_edit?(resource)`, which are just nice shortcuts for `resource.editable_by?(user)`.

### Models

In your models, simply `include Authority::Abilities`. This sets up both class-level and instance-level methods like `creatable_by?(user)`, etc, all of which delegate to the model's corresponding authorizer. For example, the `Rabbit` model would delegate to `RabbitAuthorizer`.

### Controllers

#### Basic Usage

In your controllers, add this method call:

`check_authorization_on ModelName`

That sets up a `:before_filter` that calls your class-level methods before each action. For instance, before running the `update` action, it will check whether `ModelName` is `updatable_by?` the current user at a class level. A return value of false means "this user can never update models of this class."

If that's all you need, one line does it.

#### In-action usage

If you need to check some attributes of a model instance to decide if an action is permissible, you can use `check_authorization_for(:action, @model_instance, @user)`

### Authorizers

Authorizers should be added under `app/authorizers`, one for each of your models. Each authorizer should correspond to a single model. So if you have `app/models/laser_cannon.rb`, you should have, at minimum:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
    end

These are where your actual authorization logic goes. You do have to specify your own business rules, but Authority comes with the following baked in:

- All instance-level methods defined on `Authority::Authorizer` call their corresponding class-level method by default. In other words, if you haven't said whether a user can update **this particular** widget, we'll decide by checking whether they can update **any** widget.
- All class-level methods defined on `Authority::Authorizer` will use the `default_strategy` you define in your configuration.
- The **default** default strategy simply returns false; you must override it in your configuration and/or write methods on your individual `Authorizer` classes to grant permissions. This whitelisting approach will keep you from accidentally allowing things you didn't intend.

This combination means that, with this code:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
    end

... you can already do the following:

    current_user.can_create?(LaserCannon)    # false; all inherited class-level permissions are false
    current_user.can_create?(@laser_cannon)  # false; instance-level permissions check class-level ones by default

If you update your authorizer as follows:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer

      def self.creatable_by?(user) # class-level permission
        true
      end

      def deletable_by?(user)      # instance_level permission
        user.first_name == 'Larry' && Date.today.friday?
      end

    end

... you can now do this following:

    current_user.can_create?(LaserCannon)    # true, per class method above
    current_user.can_create?(@laser_cannon)  # true; inherited instance method calls class method
    current_user.can_delete?(@laser_cannon)  # Only Larry, and only on Fridays

## Integration Notes

- If you want to have nice log messages for security violations, you should ensure that your user object has a `to_s` method; this will control how it shows up in log messages saying things like "Harvey Johnson is not allowed to delete this resource:..."

## Credits AKA Shout-Outs

- @adamhunter for pairing with me on this gem.
- @nkallen for [this lovely blog on access control](http://pivotallabs.com/users/nick/blog/articles/272-access-control-permissions-in-rails) when he worked at Pivotal Labs.
- @jnunemaker for creating Canable, another inspiration for Authority.

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

- Document syntax for checking rules during a controller action
- Update generator to create an authorizer for every model
- Generator
  - Add generators or hook into existing rails generators
  - Add generator to installation instructions
  - Generate well-commented default configuration file like Devise does (shout out!)
  - Generate 403.html, with option to skip if exists
- Note that you MUST call configure; internals aren't included until you do.
- Write about configuration file and options in Configuration section.
