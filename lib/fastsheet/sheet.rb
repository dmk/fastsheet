# frozen_string_literal: true

module Fastsheet
  # Represents a parsed spreadsheet and provides row/column enumeration.
  class Sheet
    attr_reader :file_name,
                :rows, :header,
                :width, :height

    def initialize(file_name, options = {})
      # this method sets @rows, @height and @width
      read!(file_name)

      @header = @rows.shift if options[:header]
    end

    def row(index)
      @rows[index]
    end

    def each_row(&)
      if block_given?
        @rows.each(&)
      else
        @rows.each
      end
    end

    def column(index)
      @rows.map { |row_values| row_values[index] }
    end

    def each_column(&)
      num_columns = compute_number_of_columns
      enumerator = Enumerator.new { |yielder| yield_each_column(yielder, num_columns) }

      return enumerator unless block_given?

      enumerator.each(&)
    end

    private

    def compute_number_of_columns
      return 0 unless @rows && !@rows.empty?

      @rows.map(&:length).max || 0
    end

    def yield_each_column(yielder, num_columns)
      index = 0
      while index < num_columns
        yielder << column(index)
        index += 1
      end
    end
  end
end
