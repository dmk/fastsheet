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

    def each_row
      if block_given?
        @rows.each { |r| yield r }
      else
        @rows.each
      end
    end

    def column(n)
      @rows.map { |r| r[n] }
    end

    def columns
      (0...@width).inject([]) do |cols, i|
        cols.push column(i)
      end
    end

    def each_column
      if block_given?
        columns.each { |c| yield c }
      else
        columns.each
      end
    end
  end
end
