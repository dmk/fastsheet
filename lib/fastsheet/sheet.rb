# frozen_string_literal: true

module Fastsheet
  # Represents a parsed spreadsheet and provides row/column enumeration.
  class Sheet
    attr_reader :file_name,
                :rows, :header,
                :width, :height,
                :worksheet_name

    def initialize(file_name, options = {})
      # Extract worksheet option, default to first worksheet (index 0)
      worksheet = options.delete(:worksheet) || 0

      # this method sets @rows, @height and @width
      read!(file_name, worksheet.to_s)
      @worksheet_name = worksheet.to_s

      @header = @rows.shift if options[:header]

      # Pre-compute and cache columns for efficient access
      @columns = nil
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
      columns[index]
    end

    def columns
      @columns ||= compute_columns
    end

    def each_column(&)
      cols = columns
      enumerator = Enumerator.new { |yielder| cols.each { |col| yielder << col } }

      return enumerator unless block_given?

      enumerator.each(&)
    end

    private

    def compute_columns
      return [] unless @rows && !@rows.empty?

      num_columns = @rows.map(&:length).max || 0
      return [] if num_columns.zero?

      Array.new(num_columns) do |col_index|
        @rows.map { |row_values| row_values[col_index] }
      end
    end

    def compute_number_of_columns
      return 0 unless @rows && !@rows.empty?

      @rows.map(&:length).max || 0
    end
  end
end
