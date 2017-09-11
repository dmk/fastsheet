# Fastsheet

Fastest ruby gem for reading Excel documents.

Benchmark:
```shell
$ bin/benchmark
Benchmark reading row №2991 from `./first_file.xlsx` 15 times...
┌───────────┬───────────┐
│   Reader  │ Real Time │
├───────────┼───────────┤
│    Roo    │ 161.3275  │
├───────────┼───────────┤
│ Fastsheet │  4.3765   │
└───────────┴───────────┘
Fastsheet is 37 times faster

$ bin/benchmark
Benchmark reading row №7146 from `./second_file.xlsx` 15 times...
┌───────────┬───────────┐
│   Reader  │ Real Time │
├───────────┼───────────┤
│    Roo    │ 897.4474  │
├───────────┼───────────┤
│ Fastsheet │  19.0869  │
└───────────┴───────────┘
Fastsheet is 47 times faster
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fastsheet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fastsheet

## Usage

This lib returns sheet as array of arrays, so you are free to use it however you want:

```ruby
require 'fastsheet'

sheet = Xlsx.new('path/to/sheet.xlsx')

 # get all rows
sheet.rows
```

That's all API for now :smile: . Feel free to [open an issue](http://github.com/dkkoval/fastsheet/issues) if you need more.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dkkoval/fastsheet.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
