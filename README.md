# Elephrame

A framework that helps simplify the creation of bots for mastodon/pleroma

Uses rufus-scheduler in the backend

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elephrame'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elephrame

## Quickstart

bot that posts "i'm gay" every three hours:

```ruby
require 'elephrame'

my_bot = Elephrame::Bots::Periodic.new '3h'

my_bot.run { |bot|
  bot.post("i'm gay")
}
```

	$ INSTANCE="mastodon.social" TOKEN="your_access_token" ruby bot.rb

Check the [examples](https://github.com/theZacAttacks/elephrame/examples) directory for more example bots

### Bot Types

So far the framework support 4 bot types: Periodic, Interact, PeroidInteract, Reply

- `Periodic` supports posting on a set schedule
- `Interact` supports callbacks for each type of interaction (favorites, boosts, replies, follows)
- `PeriodInteract` supports both of the above (I know, this isn't a good name)
- `Reply` only supports replying to mentions

The string passed to `Periodic` and `PeroidInteract` must be either a 'Duration' string or a 'Cron' string, as parsable by [fugit](https://github.com/floraison/fugit)

## Usage

TODO: api docs
TODO: usage docs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/theZacAttacks/elephrame. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Elephrame project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/theZacAttacks/elephrame/blob/master/CODE_OF_CONDUCT.md).
