# frozen_string_literal: true

module Fastsheet
  # Validates opt-in value conversion policies before entering the native reader.
  class ValueOptions
    CHOICES = {
      dates: %i[time date excel_serial],
      timezone: %i[local utc],
      errors: %i[nil string],
      strip_strings: [true, false],
      blank_strings: %i[nil preserve]
    }.transform_values(&:freeze).freeze

    def initialize(options)
      @values = CHOICES.to_h do |name, choices|
        value = options.fetch(name, choices.first)
        unless choices.include?(value)
          raise ArgumentError, "#{name} must be one of #{choices.map(&:inspect).join(', ')}"
        end

        [name, value]
      end
      require 'date' if @values[:dates] == :date
    end

    def native_arguments
      [@values[:dates] == :excel_serial, @values[:errors] == :string,
       @values[:strip_strings], @values[:blank_strings] == :preserve]
    end

    def convert_times!(rows)
      return if @values[:dates] == :excel_serial
      return if @values[:dates] == :time && @values[:timezone] == :local

      rows.each do |row|
        row.map! { |value| value.is_a?(Time) ? convert_time(value) : value }
      end
    end

    private

    def convert_time(value)
      @values[:dates] == :date ? value.getutc.to_date : value.utc
    end
  end

  private_constant :ValueOptions
end
