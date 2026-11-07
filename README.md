# Fastsheet

Fastest ruby gem for reading Excel documents.

## Installation

**You should have Rust installed to build this gem.** Tested with Ruby 3.2+.

Add this line to your application's Gemfile:

```ruby
gem 'fastsheet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fastsheet

## Usage

### Basic Usage

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
sheet.row(42)
sheet.column(1)
```

Iterators (returns enumerator if no block given):

```ruby
sheet.each_row { |r| ... }
sheet.each_column { |c| ... }
sheet.each_column.to_a # materialize columns if you need them all
```

### Sheet Selection

Read specific sheets from multi-sheet workbooks:

```ruby
# Read sheet by name
sheet = Fastsheet::Sheet.new('path/to/workbook.xlsx', sheet: 'Data')

# Read sheet by index (0-based)
sheet = Fastsheet::Sheet.new('path/to/workbook.xlsx', sheet: 1)

# Get information about available sheets
sheet_names = Fastsheet::Sheet.sheet_names('path/to/workbook.xlsx')
# => ['Sheet1', 'Data', 'Summary']

sheet_count = Fastsheet::Sheet.sheet_count('path/to/workbook.xlsx')
# => 3

# Access current sheet information
sheet.sheet_name   # => 'Data'
sheet.sheet_index  # => 1
```

### Headers and Options

All existing options work with sheet selection:

```ruby
# Read specific sheet with header row
sheet = Fastsheet::Sheet.new('path/to/workbook.xlsx',
                             sheet: 'Data',
                             header: true)

sheet.header  # => ['Name', 'Age', 'City']
sheet.rows    # => [['Alice', 30, 'NYC'], ['Bob', 25, 'LA']]
```

### Error Handling

The library provides specific exceptions for invalid sheet selections:

```ruby
begin
  sheet = Fastsheet::Sheet.new('file.xlsx', sheet: 'NonExistent')
rescue Fastsheet::SheetNotFoundError => e
  puts "Sheet not found: #{e.message}"
end

begin
  sheet = Fastsheet::Sheet.new('file.xlsx', sheet: 99)
rescue Fastsheet::SheetIndexError => e
  puts "Invalid sheet index: #{e.message}"
end
```

### Backward Compatibility

Existing code continues to work unchanged. When no sheet is specified, the first sheet is read by default:

```ruby
# These are equivalent:
sheet1 = Fastsheet::Sheet.new('file.xlsx')
sheet2 = Fastsheet::Sheet.new('file.xlsx', sheet: 0)
```

## Data Types

The library automatically converts Excel data types:

- Numbers (integers and floats)
- Strings (with whitespace trimming)
- Booleans (`true`/`false`)
- Empty cells (as `nil`)
- Error cells (as `nil`)

Dates and formulas returned as `nil`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dkkoval/fastsheet.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
