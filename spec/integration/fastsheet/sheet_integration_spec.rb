# frozen_string_literal: true

require 'spec_helper'
require 'fastsheet'

RSpec.describe Fastsheet::Sheet, :integration do
  describe '#initialize' do
    it 'sets width and height' do
      file = build_temp_xlsx
      sheet = described_class.new(file.path)
      expect(sheet.width).to be_an(Integer)
      expect(sheet.height).to be_an(Integer)
    end

    it 'reads rows as array of arrays' do
      file = build_temp_xlsx
      sheet = described_class.new(file.path)
      expect(sheet.rows).to be_an(Array)
      expect(sheet.rows.length).to eq(sheet.height)
      expect(sheet.rows.first).to be_an(Array)
      expect(sheet.rows.first.length).to eq(sheet.width)
    end

    it 'honors header option' do
      header = %w[id name]
      rows = [[1, 'alice'], [2, 'bob']]
      file = build_temp_xlsx(rows: rows, header: header)
      sheet = described_class.new(file.path, header: true)
      expect(sheet.header).to be_an(Array)
      expect(sheet.rows.length + 1).to eq(sheet.height)
    end
  end

  describe '#each_row' do
    it 'returns an enumerator' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      enum = sheet.each_row
      expect(enum).to respond_to(:each)
    end

    it 'yields rows when iterated' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      rows = sheet.each_row.to_a
      expect(rows.length).to eq(sheet.height)
      expect(rows.first.length).to eq(sheet.width)
    end
  end

  describe '#each_column' do
    it 'returns an enumerator' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      enum = sheet.each_column
      expect(enum).to respond_to(:each)
    end

    it 'enumerates columns matching height' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      cols = sheet.each_column.to_a
      expect(cols.first.length).to eq(sheet.height)
    end
  end

  describe '#row' do
    it 'returns a row by index' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      expect(sheet.row(0)).to eq(sheet.rows[0])
    end
  end

  describe '#column' do
    it 'returns a column by index' do
      file = build_temp_xlsx(rows: [[1, 2], [3, 4], [5, 6]])
      sheet = described_class.new(file.path)
      expect(sheet.column(0)).to eq(sheet.rows.map { |r| r[0] })
    end
  end

  describe 'sheet selection' do
    it 'reads specified sheet by name' do
      file = build_temp_xlsx_multi_sheet
      sheet = described_class.new(file.path, sheet: 'Data')

      expect(sheet.sheet_name).to eq('Data')
      expect(sheet.height).to eq(3)
      expect(sheet.row(0)).to eq(%w[Name Age City])
      expect(sheet.row(1)).to eq(['Alice', 30, 'NYC'])
    end

    it 'reads specified sheet by index' do
      file = build_temp_xlsx_multi_sheet
      sheet = described_class.new(file.path, sheet: 1)

      expect(sheet.sheet_index).to eq(1)
      expect(sheet.sheet_name).to eq('Data')
      expect(sheet.height).to eq(3)
    end

    it 'reads specified sheet with integer index as string' do
      file = build_temp_xlsx_multi_sheet
      sheet = described_class.new(file.path, sheet: 2)

      expect(sheet.sheet_index).to eq(2)
      expect(sheet.sheet_name).to eq('Numbers')
      expect(sheet.row(0)).to eq([1, 2, 3, 4])
    end

    it 'defaults to first sheet when no sheet specified' do
      file = build_temp_xlsx_multi_sheet
      sheet = described_class.new(file.path)

      expect(sheet.sheet_name).to eq('Sheet1')
      expect(sheet.sheet_index).to eq(0)
      expect(sheet.row(0)).to eq(%w[A1 B1])
    end

    it 'works with header option and sheet selection' do
      file = build_temp_xlsx_multi_sheet
      sheet = described_class.new(file.path, sheet: 'Data', header: true)

      expect(sheet.sheet_name).to eq('Data')
      expect(sheet.header).to eq(%w[Name Age City])
      expect(sheet.rows.length).to eq(2)
      expect(sheet.row(0)).to eq(['Alice', 30, 'NYC'])
    end

    it 'raises SheetNotFoundError for invalid sheet name' do
      file = build_temp_xlsx_multi_sheet
      expect do
        described_class.new(file.path, sheet: 'NonExistent')
      end.to raise_error(Fastsheet::SheetNotFoundError, /Sheet 'NonExistent' not found/)
    end

    it 'raises SheetIndexError for invalid sheet index' do
      file = build_temp_xlsx_multi_sheet
      expect do
        described_class.new(file.path, sheet: 99)
      end.to raise_error(Fastsheet::SheetIndexError, /Sheet index 99 out of range/)
    end
  end

  describe 'class methods' do
    it 'returns sheet names' do
      file = build_temp_xlsx_multi_sheet
      names = described_class.sheet_names(file.path)

      expect(names).to eq(%w[Sheet1 Data Numbers])
    end

    it 'returns sheet count' do
      file = build_temp_xlsx_multi_sheet
      count = described_class.sheet_count(file.path)

      expect(count).to eq(3)
    end
  end
end
