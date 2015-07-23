# Regulator
[![Build Status](https://travis-ci.org/coryodaniel/regulator.svg)](https://travis-ci.org/coryodaniel/regulator)
[![Code Climate](https://codeclimate.com/github/coryodaniel/regulator/badges/gpa.svg)](https://codeclimate.com/github/coryodaniel/regulator)
[![Test Coverage](https://codeclimate.com/github/coryodaniel/regulator/badges/coverage.svg)](https://codeclimate.com/github/coryodaniel/regulator/coverage)

Regulator is a clone of the [Pundit](https://github.com/elabs/pundit) gem and provides a pundit compatible DSL that has **controller namespaced** authorization polices instead of *model namespaced*.

It uses Ruby classes and object oriented design patterns to build a simple, robust and scaleable authorization system.

Existing pundit policies can be used, although they will have to be namespaced properly, or have the controller accessing set ```Controller.policy_class``` or ```Controller.policy_namespace```

I built this because I believe authorization should be controller-based, not model based, but really enjoyed using the Pundit DSL and I was over [monkey-patching](https://gist.github.com/Systho/3d7632b5aa999cf88d87) pundit in all of my projects to make it work the way I want.

Why not contribute to pundit? [It's](https://github.com/elabs/pundit/issues/12) [been](https://github.com/elabs/pundit/issues/178) an [on going](https://github.com/elabs/pundit/search?q=namespace&type=Issues&utf8=%E2%9C%93) 'issue' in pundit and it doesn't look [like it'll be reality.](https://github.com/elabs/pundit/pull/190#issuecomment-53052356)

## TODOs
  * [ ] documentation
    * [ ] Usage section below, mock pundit's
    * [ ] yard doc
    * [ ] Lotus examples
    * [ ] Grape examples
    * [ ] ROM examples
    * [ ] Custom permissions examples
    * [ ] RoleModel gem examples
    * [ ] rolify gem examples
  * [ ] contributing wiki

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regulator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install regulator

## Usage

No docs yet, check out the [specs](https://github.com/coryodaniel/regulator/blob/master/spec/regulator_spec.rb)

### Generators

Install regulator
```bash
  rails g regulator:install
```

Create a new policy and policy test/spec
```bash
  rails g regulator:policy User
```

Regulator comes with a generator for creating an ActiveAdmin adapter
```bash
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Contributors
  * [Cory O'Daniel](http://linkedin.com/in/coryodaniel)

  Thanks to Warren G for the inspiration, bro.

  ![Regulator](https://upload.wikimedia.org/wikipedia/commons/a/ac/Nat_Powers_%26_Warren_G.jpg)
