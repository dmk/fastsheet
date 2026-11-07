# frozen_string_literal: true

require 'spec_helper'
require 'fastsheet'

RSpec.describe Fastsheet::Sheet, :integration do
  describe 'selection errors' do
    it 'treats numeric strings as names and integers as indexes' do
      file = build_temp_xlsx(sheet_name: '123')
      expect(described_class.new(file.path, sheet: '123').sheet_name).to eq('123')
      expect(described_class.new(file.path, sheet: 0).sheet_name).to eq('123')
    end

    it 'preserves percent signs in missing sheet errors' do
      file = build_temp_xlsx
      expect { described_class.new(file.path, sheet: '%s%n%') }
        .to raise_error(Fastsheet::SheetNotFoundError, "Sheet '%s%n%' not found")
    end

    it 'rejects negative and oversized indexes' do
      file = build_temp_xlsx
      [-1, 2**100].each do |index|
        expect { described_class.new(file.path, sheet: index) }.to raise_error(Fastsheet::SheetIndexError)
      end
    end

    it 'rejects invalid selector types and embedded null bytes' do
      file = build_temp_xlsx
      [true, false, :Data, 1.5, []].each do |selector|
        expect { described_class.new(file.path, sheet: selector) }.to raise_error(TypeError)
      end
      expect { described_class.new(file.path, sheet: "Data\0") }.to raise_error(ArgumentError)
      expect { described_class.sheet_names("file\0.xlsx") }.to raise_error(ArgumentError)
    end

    it 'does not modify frozen options' do
      file = build_temp_xlsx
      expect(described_class.new(file.path, { sheet: 0 }.freeze).sheet_index).to eq(0)
    end

    it 'raises Ruby errors for missing and corrupt files through every entry point' do
      file = build_temp_xlsx
      File.write(file.path, 'invalid zip')
      ["#{file.path}.missing", file.path].each do |path|
        expect { described_class.new(path) }.to raise_error(IOError)
        expect { described_class.sheet_names(path) }.to raise_error(IOError)
        expect { described_class.sheet_count(path) }.to raise_error(IOError)
      end
    end
  end

  describe 'dates and durations' do
    it 'reads dates, fractional seconds, and durations in the 1900 date system' do
      file = build_temp_xlsx_serials([25_569.0, 25_569.5, 25_569.000001, 25_568.5, 1.5])
      values = described_class.new(file.path).row(0)
      expect(values.first(4).map(&:to_f)).to eq([0.0, 43_200.0, 0.086, -43_200.0])
      expect(values.last).to eq(129_600.0)
    end

    it 'handles the Excel 1900 leap-day boundary' do
      { 1.0 => [1900, 1, 1], 59.0 => [1900, 2, 28],
        60.0 => [1900, 2, 28], 61.0 => [1900, 3, 1] }.each do |serial, date|
        file = build_temp_xlsx_serials([serial])
        expect(described_class.new(file.path).row(0).first).to eq(Time.utc(*date))
      end
    end

    it 'returns nil for numeric dates outside the supported range' do
      file = build_temp_xlsx_serials([1e20])
      expect(described_class.new(file.path).row(0).first).to be_nil
    end

    it 'reads the 1904 date system' do
      file = build_temp_xlsx_serials([24_107.0], date1904: true)
      expect(described_class.new(file.path).row(0).first.to_i).to eq(0)
    end
  end
end
