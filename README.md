# Fastsheet

Fastest ruby gem for reading Excel documents.

## Installation

**You need Rust 1.88 or newer to build this gem.** Tested with Ruby 3.2+.

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
- Numeric Excel dates and times (as Ruby `Time`, interpreted as UTC instants; display follows the local timezone)
- Numeric Excel durations such as `[h]:mm:ss` (as seconds, `Float`)
- ISO dates and durations (as strings)

Unrepresentable numeric dates return `nil`. Formula cells expose cached values when present;
formula text and recalculation are not exposed.

Sheet selectors are type-sensitive: integers select zero-based indexes, while strings
select exact sheet names, including numeric names such as `"123"`. Invalid selector
types raise `TypeError`; missing or unreadable files raise `IOError`.

### Value Conversion Options

Conversion options apply to all cells, including the extracted header. Defaults
preserve the behavior described above.

| Option | Default | Alternatives |
| --- | --- | --- |
| `dates` | `:time` | `:date` returns Ruby `Date`; `:excel_serial` returns the original numeric date/time serial |
| `timezone` | `:local` | `:utc` returns `Time` objects displayed in UTC |
| `errors` | `:nil` | `:string` returns Excel error text such as `"#DIV/0!"` or `"#N/A"` |
| `strip_strings` | `true` | `false` preserves string whitespace supplied by the parser |
| `blank_strings` | `:nil` | `:preserve` keeps empty strings after optional trimming |

```ruby
sheet = Fastsheet::Sheet.new('workbook.xlsx',
                             dates: :date,
                             errors: :string,
                             strip_strings: false,
                             blank_strings: :preserve)
```

Excel numeric dates contain no timezone. `timezone` controls display only: both
settings interpret the spreadsheet clock as UTC. `dates: :date` uses that clock's
calendar day, regardless of the local timezone, and discards the time of day.
This explicitly converts all numeric date/time cells; it does not infer which
cells are date-only. `timezone` has no effect with `:date` or `:excel_serial`.

Numeric durations remain seconds under every date policy. ISO date and duration
strings remain strings. Raw serial mode preserves otherwise unrepresentable dates
and Excel's fictional leap-day serial `60`; `Time` and `Date` conversion map it to
February 28, 1900. A raw serial must be interpreted using its workbook's 1900 or
1904 date system.

With `strip_strings: false`, whitespace-only strings remain strings even when
`blank_strings: :nil`. Missing cells always remain `nil`. Error text in `:string`
mode has the same Ruby type as a literal string containing that text. Invalid
conversion option values raise `ArgumentError` before the file is opened.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dkkoval/fastsheet.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
