# frozen_string_literal: true

require 'caxlsx'
require 'tempfile'

module XlsxHelpers
  module_function

  # Build a temporary XLSX file and return the Tempfile instance.
  # Caller is responsible for unlinking if needed; Tempfile will clean up at GC.
  def build_temp_xlsx(rows: [[1, 2, 3], [4, 5, 6], [7, 8, 9]], header: nil, sheet_name: 'Sheet1')
    Tempfile.create(['fastsheet_spec', '.xlsx']).tap do |tmp|
      tmp.close
      Axlsx::Package.new do |package|
        package.workbook.add_worksheet(name: sheet_name) do |sheet|
          sheet.add_row(header) if header
          rows.each { |row_values| sheet.add_row(row_values) }
        end
        package.serialize(tmp.path)
      end
    end
  end
end

RSpec.configure do |config|
  config.include XlsxHelpers
end
