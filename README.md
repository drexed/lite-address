# Lite::Address

Lite::Address is an address parser and formatter.
Currently supports US and CA based addresses.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lite-address'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lite-address

## Table of Contents

* [Usage](#usage)
* [Formatting](#formatting)

## Usage

Parsing an address will return a `Lite::Address::Format` object which responds to the
methods below (check the class to see more). If an address cannot be parsed then nil
will be returned, but partial matches can be returned. All addresses will try to be
normalized to return a predictable pattern.

```
address = Lite::Address::Parse.parse("1600 Pennsylvania Ave, Washington, DC, 20500")
address.street        #=> Pennsylvania
address.number        #=> 1600
address.postal_code   #=> 20500
address.city          #=> Washington
address.state         #=> DC
address.state_name    #=> District of Columbia
address.street_type   #=> Ave
address.intersection? #=> false

address = Lite::Address::Parse.parse("1600 Pennsylvania Ave")
address.street  #=> Pennsylvania
address.number  #=> 1600
address.state   #=> nil

address = Lite::Address::Parse.parse("5904 Richmond Hwy Ste 340 Alexandria VA 22303-1864")
address.postal_code_ext #=> 1846

address = Lite::Address::Parse.parse("5904 Richmond Hwy Ste 340 Alexandria VA 223031864")
address.postal_code_ext #=> 1846
```

To parse address for non US based addresses just pass a corresponding country code.

```
address = Lite::Address::Parse.parse("1 Blue Jays Way, Toronto, ON M5V 1J1, Canada", country_code: "CA")
address.street        #=> Blue Jays
address.number        #=> 1
address.state_name    #=> Ontario
...
```

## Formatting

A formatted can be returned to as a whole or in parts of simple strings.

```
address = Lite::Address::Parse.parse("1600 Pennsylvania Ave, Washington, DC, 20500")
address.to_s         #=> 1600 Pennsylvania Ave, Washington, DC 20500
address.to_s(:line1) #=> 1600 Pennsylvania Ave
address.to_s(:line2) #=> Washington, DC 20500
```

You can also format strings to the proper country mail format.

```
address = Lite::Address::Parse.parse("1600 Pennsylvania Ave, Washington, DC, 20500")
address.to_snail                    #=> 1600 Pennsylvania Ave,
                                        Washington, DC 20500

address.to_snail(name: 'John Doe')  #=> John Doe
                                        1600 Pennsylvania Ave,
                                        Washington, DC 20500
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/lite-address. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lite::Address project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/lite-address/blob/master/CODE_OF_CONDUCT.md).
