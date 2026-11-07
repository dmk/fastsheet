# frozen_string_literal: true

module Fastsheet
  # Represents a parsed spreadsheet and provides row/column enumeration.
  class Sheet
    attr_reader :file_name,
                :rows, :header,
                :width, :height,
                :sheet_name, :sheet_index

    def initialize(file_name, options = {})
      read!(file_name, options[:sheet])
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

    def self.sheet_names(file_name)
      result = native_sheet_names(validate_file_name(file_name))
      raise IOError, result if result.is_a?(String)

      result
    end

    def self.sheet_count(file_name)
      sheet_names(file_name).length
    end

    def self.validate_file_name(file_name)
      raise TypeError, 'file name must be a String' unless file_name.is_a?(String)
      raise ArgumentError, 'file name contains a null byte' if file_name.include?("\0")

      file_name
    end
    private_class_method :validate_file_name
    private_class_method :native_sheet_names if respond_to?(:native_sheet_names)
    private :read_native! if method_defined?(:read_native!)

    def read!(file_name, selector = nil)
      self.class.send(:validate_file_name, file_name)
      selector = validate_selector(selector)
      result = read_native!(file_name, selector.to_s, selector.is_a?(Integer))
      return result unless result.is_a?(Array)

      kind, message = result
      error = { 'index' => SheetIndexError, 'name' => SheetNotFoundError }.fetch(kind, IOError)
      raise error, message
    end

    private

    def validate_selector(selector)
      return 0 if selector.nil?
      unless selector.is_a?(String) || selector.is_a?(Integer)
        raise TypeError, 'sheet must be an Integer index or String name'
      end
      raise ArgumentError, 'sheet name contains a null byte' if selector.is_a?(String) && selector.include?("\0")

      selector
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
