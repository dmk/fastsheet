require 'spec_helper'
require 'fastsheet'

RSpec.describe Fastsheet::Sheet, integration: true do
  let(:xlsx_path) do
    File.expand_path('../../../examples/xlsx/file_example_XLS_10.xls', __dir__)
  end

  it 'loads width, height and rows from a real file' do
    sheet = described_class.new(xlsx_path)
    expect(sheet.width).to be_an(Integer)
    expect(sheet.height).to be_an(Integer)
    expect(sheet.rows).to be_an(Array)
    expect(sheet.rows.length).to eq(sheet.height)
    expect(sheet.rows.first).to be_an(Array)
    expect(sheet.rows.first.length).to eq(sheet.width)
  end

  it 'supports header option' do
    sheet = described_class.new(xlsx_path, header: true)
    expect(sheet.header).to be_an(Array)
    expect(sheet.rows.length + 1).to eq(sheet.height)
  end

  it 'enumerates rows and columns' do
    sheet = described_class.new(xlsx_path)
    enum = sheet.each_row
    expect(enum).to respond_to(:each)

    enum_cols = sheet.each_column
    expect(enum_cols).to respond_to(:each)
    cols = enum_cols.to_a
    expect(cols.first.length).to eq(sheet.height)
  end

  it 'returns columns and rows indexes' do
    sheet = described_class.new(xlsx_path)
    expect(sheet.row(0)).to eq(sheet.rows[0])
    expect(sheet.column(0)).to eq(sheet.rows.map { |r| r[0] })
  end
end


