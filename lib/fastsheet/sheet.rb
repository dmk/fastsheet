# frozen_string_literal: true

module Fastsheet
  class Sheet
    attr_reader :file_name,
                :rows, :header,
                :width, :height

    def initialize(file_name, options = {})
      # this method sets @rows, @height and @width
      read!(file_name)

      @header = @rows.shift if options[:header]
    end

    def row(n)
      @rows[n]
    end

    def each_row(&)
      if block_given?
        @rows.each(&)
      else
        @rows.each
      end
    end

    def column(n)
      @rows.map { |r| r[n] }
    end

    def each_column(&)
      num_columns = @rows && !@rows.empty? ? (@rows.map(&:length).max || 0) : 0
      enumerator = Enumerator.new do |y|
        i = 0
        while i < num_columns
          y << column(i)
          i += 1
        end
      end

      return enumerator unless block_given?

      enumerator.each(&)
    end
  end
end
