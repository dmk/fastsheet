require 'spec_helper'
require 'fastsheet/sheet'

RSpec.describe Fastsheet::Sheet do
  let(:rows) { [[1, 2], [3, 4], [5, 6]] }

  before do
    allow_any_instance_of(described_class).to receive(:read!) do |instance, *_args|
      instance.instance_variable_set(:@rows, rows.map(&:dup))
      instance.instance_variable_set(:@height, rows.length)
      instance.instance_variable_set(:@width, rows.first.length)
      nil
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
end


