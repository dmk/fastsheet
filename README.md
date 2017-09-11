# Fastsheet

Fastest ruby gem for reading Excel documents.

## Installation

**You should have rust installed to use this gem.**

Add this line to your application's Gemfile:

```ruby
gem 'fastsheet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fastsheet

## Usage

Open a sheet:

```ruby
require 'fastsheet'

sheet = Fastsheet::Sheet.new('path/to/sheet.xlsx')

# number of columns
sheet.width

# number of rows
sheet.height
```

Get rows or columns:

```ruby
sheet.rows
sheet.columns

sheet.row(42)
sheet.column(1)
```

Iterators (returns enumerator if no block given):

```ruby
sheet.each_row { |r| ... }
sheet.each_column { |c| ... }
```

That's all API for now. Feel free to [open an issue](http://github.com/dkkoval/fastsheet/issues) if you need more.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dkkoval/fastsheet.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
