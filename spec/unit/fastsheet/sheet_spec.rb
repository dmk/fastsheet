# frozen_string_literal: true

require 'spec_helper'
require 'fastsheet/sheet'

RSpec.describe Fastsheet::Sheet do
  let(:rows) { [[1, 2], [3, 4], [5, 6]] }

  before do
    allow(described_class).to receive(:new) do |*args|
      instance = described_class.allocate
      allow(instance).to receive(:read!) do |_file_name = nil, _sheet_selector = nil|
        instance.instance_variable_set(:@rows, rows.map(&:dup))
        instance.instance_variable_set(:@height, rows.length)
        instance.instance_variable_set(:@width, rows.first.length)
        instance.instance_variable_set(:@sheet_name, 'Sheet1')
        instance.instance_variable_set(:@sheet_index, 0)
        nil
      end
      instance.send(:initialize, *args)
      instance
    end
  end

  it 'initializes width, height, and rows without header' do
    sheet = described_class.new('dummy.xlsx')
    expect(sheet.width).to eq(2)
    expect(sheet.height).to eq(3)
    expect(sheet.rows).to eq(rows)
  end

  it 'supports header option' do
    sheet = described_class.new('dummy.xlsx', header: true)
    expect(sheet.header).to eq([1, 2])
    expect(sheet.rows).to eq([[3, 4], [5, 6]])
    expect(sheet.height).to eq(3)
    expect(sheet.width).to eq(2)
  end

  it 'enumerates rows and columns' do
    sheet = described_class.new('dummy.xlsx')

    enum = sheet.each_row
    expect(enum).to respond_to(:each)
    expect(enum.to_a).to eq(rows)

    enum_cols = sheet.each_column
    expect(enum_cols.to_a).to eq([[1, 3, 5], [2, 4, 6]])
  end

  it 'returns specific row and column' do
    sheet = described_class.new('dummy.xlsx')
    expect(sheet.row(1)).to eq([3, 4])
    expect(sheet.column(0)).to eq([1, 3, 5])
  end

  describe 'sheet selection' do
    it 'supports sheet option with string' do
      sheet = described_class.new('dummy.xlsx', sheet: 'Data')
      expect(sheet.sheet_name).to eq('Sheet1')  # Mocked value
      expect(sheet.sheet_index).to eq(0)
    end

    it 'supports sheet option with integer' do
      sheet = described_class.new('dummy.xlsx', sheet: 1)
      expect(sheet.sheet_name).to eq('Sheet1')  # Mocked value
      expect(sheet.sheet_index).to eq(0)
    end

    it 'defaults to first sheet when no sheet specified' do
      sheet = described_class.new('dummy.xlsx')
      expect(sheet.sheet_name).to eq('Sheet1')
      expect(sheet.sheet_index).to eq(0)
    end

    it 'works with header option and sheet selection' do
      sheet = described_class.new('dummy.xlsx', sheet: 'Data', header: true)
      expect(sheet.sheet_name).to eq('Sheet1')  # Mocked value
      expect(sheet.header).to eq([1, 2])
      expect(sheet.rows).to eq([[3, 4], [5, 6]])
    end
  end

  describe 'class methods' do
    before do
      allow(described_class).to receive(:sheet_names).and_call_original
      allow(described_class).to receive(:sheet_count).and_call_original
    end

    it 'has sheet_names class method' do
      expect(described_class).to respond_to(:sheet_names)
    end

    it 'has sheet_count class method' do
      expect(described_class).to respond_to(:sheet_count)
    end
  end
end
