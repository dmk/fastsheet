# frozen_string_literal: true

module Fastsheet
  # Represents a parsed spreadsheet and provides row/column enumeration.
  class Sheet
    attr_reader :file_name,
                :rows, :header,
                :width, :height,
                :sheet_name, :sheet_index

    def initialize(file_name, options = {})
      sheet_selector = normalize_sheet_selector(options[:sheet])
      load_sheet_data(file_name, sheet_selector)
      extract_header_if_requested(options[:header])
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

    def normalize_sheet_selector(sheet)
      return sheet.to_s if sheet.is_a?(Integer)

      sheet
    end

    def load_sheet_data(file_name, sheet_selector)
      read!(file_name, sheet_selector)
    rescue RuntimeError => e
      handle_sheet_loading_error(e)
    end

    def handle_sheet_loading_error(error)
      case error.message
      when /Sheet '(.+)' not found/
        raise SheetNotFoundError, error.message
      when /Sheet index (\d+) out of range/
        raise SheetIndexError, error.message
      else
        raise
      end
    end

    def extract_header_if_requested(header_option)
      @header = @rows.shift if header_option
    end

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
