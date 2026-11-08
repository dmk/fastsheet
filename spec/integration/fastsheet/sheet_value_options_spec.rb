# frozen_string_literal: true

require 'spec_helper'
require 'fastsheet'
require 'date'

RSpec.describe Fastsheet::Sheet, :integration do
  let(:dates_file) { build_temp_xlsx_serials([25_569.0, 25_569.5, 25_569.000001, 1.5]) }
  let(:values_file) do
    file = build_temp_xlsx(rows: [[1]], sheet_name: 'Data')
    rewrite_xlsx_entry(file.path, 'xl/worksheets/sheet1.xml') do |xml|
      cells = <<~XML
        <c r="A1" t="inlineStr"><is><t xml:space="preserve">  Alice  </t></is></c>
        <c r="B1" t="inlineStr"><is><t xml:space="preserve"></t></is></c>
        <c r="C1" t="inlineStr"><is><t xml:space="preserve">   </t></is></c>
        <c r="D1"/>
        <c r="E1" t="e"><v>#DIV/0!</v></c>
        <c r="F1" t="e"><v>#N/A</v></c>
        <c r="G1" t="inlineStr"><is><t>#N/A</t></is></c>
        <c r="H1" t="n"><v>42</v></c>
        <c r="I1" t="b"><v>1</v></c>
        <c r="J1" t="d"><v>2024-06-01T12:30:00</v></c>
      XML
      xml.sub(%r{<sheetData>.*?</sheetData>}m, "<sheetData><row r=\"1\">#{cells}</row></sheetData>")
    end
    file
  end

  around do |example|
    previous_timezone = ENV.fetch('TZ', nil)
    ENV['TZ'] = 'Etc/GMT+8'
    example.run
  ensure
    ENV['TZ'] = previous_timezone
  end

  describe 'date policies' do
    it 'keeps the existing UTC-instant and local-display convention by default' do
      value = described_class.new(dates_file.path).row(0).first
      expect(value).to eq(Time.utc(1970, 1, 1))
      expect(value.utc_offset).to eq(-28_800)
      expect(value.hour).to eq(16)
    end

    it 'returns UTC Time objects with fractional seconds when requested' do
      values = described_class.new(dates_file.path, timezone: :utc).row(0)
      expect(values.first(3)).to all(be_utc)
      expect(values.first(3).map(&:to_f)).to eq([0.0, 43_200.0, 0.086])
      expect(values.last).to eq(129_600.0)
    end

    it 'converts numeric dates using their spreadsheet calendar day' do
      values = described_class.new(dates_file.path, dates: :date).row(0)
      expect(values.first(3)).to eq(Array.new(3, Date.new(1970, 1, 1)))
      expect(values.last).to eq(129_600.0)
    end

    it 'returns raw date serials while keeping numeric durations in seconds' do
      values = described_class.new(dates_file.path, dates: :excel_serial).row(0)
      expect(values).to eq([25_569.0, 25_569.5, 25_569.000001, 129_600.0])
    end

    it 'preserves raw serials for the 1904 epoch and unrepresentable dates' do
      file = build_temp_xlsx_serials([24_107.0, 1e20, 1.5], date1904: true)
      expect(described_class.new(file.path, dates: :excel_serial).row(0)).to eq([24_107.0, 1e20, 129_600.0])
    end

    it 'converts 1904 dates to Date and keeps out-of-range dates nil' do
      file = build_temp_xlsx_serials([24_107.0, 1e20, 1.5], date1904: true)
      expect(described_class.new(file.path, dates: :date).row(0)).to eq([Date.new(1970, 1, 1), nil, 129_600.0])
    end

    it 'retains the fictional leap-day serial while converting it to a real calendar date' do
      file = build_temp_xlsx_serials([60.0])
      expect(described_class.new(file.path, dates: :excel_serial).row(0)).to eq([60.0])
      expect(described_class.new(file.path, dates: :date).row(0)).to eq([Date.new(1900, 2, 28)])
    end

    it 'leaves ISO date strings unchanged under every policy' do
      %i[time date excel_serial].each do |policy|
        expect(described_class.new(values_file.path, dates: policy).row(0).last).to eq('2024-06-01T12:30:00')
      end
    end
  end

  describe 'string and error policies' do
    it 'keeps default normalization and ordinary values' do
      expect(described_class.new(values_file.path).row(0))
        .to eq(['Alice', nil, nil, nil, nil, nil, '#N/A', 42.0, true, '2024-06-01T12:30:00'])
    end

    it 'preserves whitespace without changing the empty-string policy' do
      values = described_class.new(values_file.path, strip_strings: false).row(0)
      expect(values.first(4)).to eq(['  Alice  ', nil, '   ', nil])
    end

    it 'preserves normalized blank strings separately from missing cells' do
      values = described_class.new(values_file.path, blank_strings: :preserve).row(0)
      expect(values.first(4)).to eq(['Alice', '', '', nil])
    end

    it 'combines policies with named sheet selection and header extraction' do
      options = { sheet: 'Data', header: true, strip_strings: false, blank_strings: :preserve, errors: :string }.freeze
      sheet = described_class.new(values_file.path, options)
      expect(sheet.header.first(9)).to eq(['  Alice  ', '', '   ', nil, '#DIV/0!', '#N/A', '#N/A', 42.0, true])
      expect(sheet.rows).to be_empty
    end

    it 'applies date conversion before extracting the header' do
      sheet = described_class.new(dates_file.path, dates: :date, header: true)
      expect(sheet.header.first).to eq(Date.new(1970, 1, 1))
      expect(sheet.rows).to be_empty
    end

    it 'preserves error text without modifying numeric, boolean, or empty cells' do
      values = described_class.new(values_file.path, errors: :string).row(0)
      expect(values[3..8]).to eq([nil, '#DIV/0!', '#N/A', '#N/A', 42.0, true])
    end
  end

  describe 'option validation' do
    it 'rejects invalid policies before opening the file' do
      { dates: :guess, timezone: 'utc', errors: true, strip_strings: nil, blank_strings: false }.each do |name, value|
        expect { described_class.new('missing.xlsx', name => value) }.to raise_error(ArgumentError, /#{name}/)
      end
    end

    it 'accepts explicit defaults without mutating frozen options' do
      options = { dates: :time, timezone: :local, errors: :nil, strip_strings: true, blank_strings: :nil }.freeze
      expect(described_class.new(values_file.path, options).rows).to eq(described_class.new(values_file.path).rows)
    end

    it 'keeps policies local to each reader' do
      preserved = described_class.new(values_file.path, strip_strings: false, errors: :string)
      normalized = described_class.new(values_file.path)
      expect(preserved.row(0).values_at(0, 4)).to eq(['  Alice  ', '#DIV/0!'])
      expect(normalized.row(0).values_at(0, 4)).to eq(['Alice', nil])
    end
  end
end
