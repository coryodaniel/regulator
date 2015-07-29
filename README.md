# Regulator
[![Build Status](https://travis-ci.org/coryodaniel/regulator.svg)](https://travis-ci.org/coryodaniel/regulator)
[![Code Climate](https://codeclimate.com/github/coryodaniel/regulator/badges/gpa.svg)](https://codeclimate.com/github/coryodaniel/regulator)
[![Test Coverage](https://codeclimate.com/github/coryodaniel/regulator/badges/coverage.svg)](https://codeclimate.com/github/coryodaniel/regulator/coverage)

Regulator is a clone of the [Pundit](https://github.com/elabs/pundit) gem and provides a pundit compatible DSL that has **controller namespaced** authorization polices instead of *model namespaced*.

It uses Ruby classes and object oriented design patterns to build a simple, robust and scaleable authorization system.

Existing pundit policies can be used, although they will have to be namespaced properly, or have the controller accessing set ```Controller.policy_class``` or ```Controller.policy_namespace```

I built this because I believe authorization should be controller-based, not model based, but really enjoyed using the Pundit DSL and I was over [monkey-patching](https://gist.github.com/Systho/3d7632b5aa999cf88d87) pundit in all of my projects to make it work the way I want.

Why not contribute to pundit? [It's](https://github.com/elabs/pundit/issues/12) [been](https://github.com/elabs/pundit/issues/178) an [on going](https://github.com/elabs/pundit/search?q=namespace&type=Issues&utf8=%E2%9C%93) 'issue' in pundit and it doesn't look [like it'll be reality.](https://github.com/elabs/pundit/pull/190#issuecomment-53052356)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regulator'
```
And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regulator

Include Regulator in your application controller:

``` ruby
class ApplicationController < ActionController::Base
  include Regulator
  protect_from_forgery
end
```

## Generators

Install regulator
``` sh
  rails g regulator:install
```

Create a new policy and policy test/spec
``` sh
  rails g regulator:policy User
```

Regulator comes with a generator for creating an ActiveAdmin adapter
``` sh
  rails g regulator:activeadmin
```

This will create an adapter in your ```lib``` folder.

Be sure to set the following in your ActiveAdmin initializer:
```ruby
config.authorization_adapter = "ActiveAdmin::RegulatorAdapter"

# Optional
# Sets a scope for all ActiveAdmin polices to exist in
#
# Example
# app/policies/admin_policies/user_policy.rb #=> AdminPolicies::UserPolicy
#
# config.regulator_policy_namespace = "AdminPolicies"
config.regulator_policy_namespace = nil

# Optional
# Sets the default policy to use if no policy is found
#
# config.regulator_default_policy = BlackListPolicy
config.regulator_default_policy = nil
```

## Policies

Regulator is focused around the notion of policy classes. We suggest that you put
these classes in `app/policies`. This is a simple example that allows updating
a post if the user is an admin, or if the post is unpublished:

``` ruby
class PostPolicy
  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def update?
    user.admin? or not post.published?
  end
end
```

Regulator makes the following assumptions about this class:

- The class has the name `Scope` and is nested under the policy class.
- The first argument is a user. In your controller, Regulator will call the
  `current_user` method to retrieve what to send into this argument.
- The second argument is a scope of some kind on which to perform some kind of
  query. It will usually be an ActiveRecord class or a
  `ActiveRecord::Relation`, but it could be something else entirely.
- Instances of this class respond to the method `resolve`, which should return
  some kind of result which can be iterated over. For ActiveRecord classes,
  this would usually be an `ActiveRecord::Relation`.

You'll probably want to inherit from the application policy scope generated by the
generator, or create your own base class to inherit from:

``` ruby
class PostPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(:published => true)
      end
    end
  end

  def update?
    user.admin? or not post.published?
  end
end
```

You can now use this class from your controller via the `policy_scope` method:

``` ruby
def index
  @posts = policy_scope(Post)
end
```

Just as with your policy, this will automatically infer that you want to use
the `PostPolicy::Scope` class, it will instantiate this class and call
`resolve` on the instance. In this case it is a shortcut for doing:

``` ruby
def index
  @posts = PostPolicy::Scope.new(current_user, Post).resolve
end
```

You can, and are encouraged to, use this method in views:

``` erb
<% policy_scope(@user.posts).each do |post| %>
  <p><%= link_to post.title, post_path(post) %></p>
<% end %>
```

## Manually specifying policy classes

Sometimes you might want to explicitly declare which policy to use for a given
class, instead of letting Regulator infer it. This can be done like so:

Regulator supports the Pundit-style model "policy_class", but also implements it
at the controller level. You can also set a controller's policy_namespace if you want to use an alternate namespace to the one the controller is in.


``` ruby
# Model level
class Post
  def self.policy_class
    PostablePolicy
  end
end
```

``` ruby
# Controller level
class Api::Post
  # By default, Regulator will look for Api::PostPolicy
  def self.policy_class
    PostPolicy
  end
end
```

``` ruby
# Here the admin namespace could be told to use the same policy as the API namespace
class Admin::Post
  # By default, Regulator will look for Admin::PostPolicy
  def self.policy_class
    PostPolicy
  end

  # You can also set it at the instance level
  def policy_class
    if current_user.is_a_high_paying_member?
      HighClassPostPolicy
    else
      LowClassPostPolicy
    end
  end
end
```

``` ruby
class Admin::Comment
  def self.policy_namespace
    # Will make regulator look for ActiveAdmin::CommentPolicy instead of
    # Admin::CommentPolicy
    ActiveAdmin
  end
end
```

Of course ```policy_namespace``` and ```policy_class``` can be used together.

## Policy Namespaces

This table explains what policies Regulator will look for in different scenarios:

| Controller Name                                        | Model Name       | Expected Policy                |
| -------------------------------------------------------|------------------| -------------------------------|
| AlbumController                                        | Album            |  AlbumPolicy                   |
| Api::AlbumController                                   | Album            |  Api::AlbumPolicy              |
| Admin::AlbumController                                 | Album            |  Admin::AlbumPolicy            |
| Admin::AlbumController.policy_namespace = 'SuperUser'  | Album            |  SuperUser::AlbumPolicy        |
| Admin::AlbumController.policy_namespace = nil          | Album            |  AlbumPolicy                   |
| Admin::AlbumContoller                                  | MySongGem::Album |  Admin::MySongGem::AlbumPolicy |
| SongController#policy_class = TrackPolicy              | Song             |  TrackPolicy                   |
| SongController.policy_class = Legacy::TrackPolicy      | Song             |  Legacy::TrackPolicy           |

```policy_class``` at the controller-level is king. Setting it will override all logic for determining the policy to use.

## ActiveAdmin Auth Adapter

There is a generator and an included adapter. Using the generator will place a more complex customizable adapter in your ```lib``` directory.

A simple adapter is also provided, to use add the following to your active_admin initializer:
``` ruby
ActiveAdmin::Dependency.regulator!

require 'regulator'
require 'regulator/active_admin_adapter'
ActiveAdmin.setup do |config|
  config.authorization_adapter = "Regulator::ActiveAdminAdapter"
  ...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contributors
  * [Cory O'Daniel](http://linkedin.com/in/coryodaniel)
  * All the hard work done on [Pundit](https://github.com/elabs/pundit)

  Thanks to Warren G for the inspiration, bro.

  ![Regulator](https://upload.wikimedia.org/wikipedia/commons/a/ac/Nat_Powers_%26_Warren_G.jpg)

## TODOs
  * [ ] documentation
    * [ ] yard doc
    * [ ] Lotus examples
    * [ ] Grape examples
    * [ ] ROM examples
    * [ ] Custom permissions examples
    * [ ] RoleModel gem examples
    * [ ] rolify gem examples
  * [ ] contributing wiki
