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
end
