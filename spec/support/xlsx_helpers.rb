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

  # Build a temporary XLSX file with multiple sheets
  def build_temp_xlsx_multi_sheet
    Tempfile.create(['fastsheet_multi_spec', '.xlsx']).tap do |tmp|
      tmp.close
      create_multi_sheet_workbook(tmp.path)
    end
  end

  def create_multi_sheet_workbook(file_path)
    Axlsx::Package.new do |package|
      add_basic_sheet(package.workbook)
      add_data_sheet(package.workbook)
      add_numbers_sheet(package.workbook)
      package.serialize(file_path)
    end
  end

  def add_basic_sheet(workbook)
    workbook.add_worksheet(name: 'Sheet1') do |sheet|
      sheet.add_row %w[A1 B1]
      sheet.add_row %w[A2 B2]
    end
  end

  def add_data_sheet(workbook)
    workbook.add_worksheet(name: 'Data') do |sheet|
      sheet.add_row %w[Name Age City]
      sheet.add_row ['Alice', 30, 'NYC']
      sheet.add_row ['Bob', 25, 'LA']
    end
  end

  def add_numbers_sheet(workbook)
    workbook.add_worksheet(name: 'Numbers') do |sheet|
      sheet.add_row [1, 2, 3, 4]
      sheet.add_row [5, 6, 7, 8]
      sheet.add_row [9, 10, 11, 12]
    end
  end
end

RSpec.configure do |config|
  config.include XlsxHelpers
end
