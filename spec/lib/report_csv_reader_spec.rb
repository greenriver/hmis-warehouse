###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../lib/report_csv_reader'

RSpec.describe ReportCsvReader, type: :lib do
  let(:test_report_class) do
    klass = Class.new(SimpleReports::ReportInstance) do
      has_many_attached :clients_csv
    end
    # Give the class a name so Active Storage can work properly
    class_name = "TestReportForCsvReader#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  let(:report) { test_report_class.create!(user_id: User.system_user.id) }
  let(:reader) { described_class.new(report, :clients_csv) }

  def create_report_without_attachment
    klass = Class.new(SimpleReports::ReportInstance) do
      # No attachment defined
    end
    class_name = "TestReportNoAttachment#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass.create!(user_id: User.system_user.id)
  end

  describe '#attached?' do
    it 'returns false when no file is attached' do
      expect(reader.attached?).to be false
    end

    it 'returns true when file is attached' do
      report.clients_csv.attach(
        io: StringIO.new('id,name\n1,Client 1'),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )
      expect(reader.attached?).to be true
    end
  end

  describe '#all' do
    it 'returns empty array when no file is attached' do
      expect(reader.all).to eq([])
    end

    it 'parses CSV and returns array of hashes' do
      csv_content = "id,name,age\n1,Client 1,25\n2,Client 2,30"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      results = reader.all
      expect(results.length).to eq(2)
      expect(results.first[:id]).to eq('1')
      expect(results.first[:name]).to eq('Client 1')
      expect(results.first[:age]).to eq('25')
    end

    it 'uses symbol keys for headers' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      results = reader.all
      # We now use symbol keys consistently
      expect(results.first.keys).to all(be_a(Symbol))
      expect(results.first.keys).to contain_exactly(:id, :name)
      expect(results.first[:id]).to eq('1')
      expect(results.first[:name]).to eq('Client 1')
    end
  end

  describe '#find_by' do
    before do
      csv_content = "id,name,age\n1,Client 1,25\n2,Client 2,30"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )
    end

    it 'finds record matching all conditions' do
      result = reader.find_by(id: '1', name: 'Client 1')
      expect(result).to be_present
      expect(result[:id]).to eq('1')
    end

    it 'returns nil when no match found' do
      result = reader.find_by(id: '999')
      expect(result).to be_nil
    end

    it 'handles string keys in conditions' do
      result = reader.find_by('id' => '1')
      expect(result).to be_present
      expect(result[:id]).to eq('1')
    end

    it 'raises error when attachment method does not exist' do
      report_no_attachment = create_report_without_attachment
      reader = described_class.new(report_no_attachment, :nonexistent_csv)
      expect { reader.find_by(id: '1') }.to raise_error(NoMethodError)
    end
  end

  describe '#where' do
    before do
      csv_content = "id,name,age\n1,Client 1,25\n2,Client 2,30\n3,Client 1,35"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )
    end

    it 'returns all matching records' do
      results = reader.where(name: 'Client 1')
      expect(results.length).to eq(2)
      expect(results.map { |r| r[:id] }).to contain_exactly('1', '3')
    end

    it 'returns empty array when no matches' do
      results = reader.where(name: 'Nonexistent')
      expect(results).to eq([])
    end

    it 'handles string keys in conditions' do
      results = reader.where('name' => 'Client 1')
      expect(results.length).to eq(2)
    end

    it 'raises error when attachment method does not exist' do
      report_no_attachment = create_report_without_attachment
      reader = described_class.new(report_no_attachment, :nonexistent_csv)
      expect { reader.where(name: 'Client 1') }.to raise_error(NoMethodError)
    end
  end

  describe '#pluck' do
    before do
      csv_content = "id,name,age\n1,Client 1,25\n2,Client 2,30"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )
    end

    it 'extracts values for specified column' do
      names = reader.pluck(:name)
      expect(names).to eq(['Client 1', 'Client 2'])
    end

    it 'extracts multiple columns' do
      results = reader.pluck(:name, :age)
      expect(results).to eq([['Client 1', '25'], ['Client 2', '30']])
    end

    it 'handles missing columns gracefully' do
      results = reader.pluck(:nonexistent_column)
      expect(results).to eq([nil, nil])
    end

    it 'raises error when attachment method does not exist' do
      report_no_attachment = create_report_without_attachment
      reader = described_class.new(report_no_attachment, :nonexistent_csv)
      expect { reader.pluck(:name) }.to raise_error(NoMethodError)
    end
  end

  describe '#count' do
    it 'returns 0 when no file attached' do
      expect(reader.count).to eq(0)
    end

    it 'returns number of rows' do
      csv_content = "id,name\n1,Client 1\n2,Client 2\n3,Client 3"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.count).to eq(3)
    end
  end

  describe '#empty?' do
    it 'returns true when no file attached' do
      expect(reader.empty?).to be true
    end

    it 'returns false when file has data' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.empty?).to be false
    end
  end

  describe '#loaded?' do
    it 'returns false before data is loaded' do
      expect(reader.loaded?).to be false
    end

    it 'returns true after data is loaded' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      reader.all
      expect(reader.loaded?).to be true
    end
  end

  describe '#load!' do
    it 'returns false when not attached' do
      expect(reader.load!).to be false
    end

    it 'returns false when attachment is nil' do
      allow(report).to receive(:clients_csv).and_return(double(attached?: true, first: nil))
      expect(reader.load!).to be false
    end

    it 'returns true when successfully loaded' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.load!).to be true
      expect(reader.loaded?).to be true
    end
  end

  describe '#any?' do
    it 'returns false when no file attached' do
      expect(reader.any?).to be false
    end

    it 'returns false when file is empty' do
      csv_content = "id,name\n"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.any?).to be false
    end

    it 'returns true when file has data' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.any?).to be true
    end
  end

  describe 'edge cases' do
    it 'handles empty CSV file' do
      csv_content = ''
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.all).to eq([])
      expect(reader.count).to eq(0)
    end

    it 'handles CSV with only headers' do
      csv_content = "id,name\n"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      expect(reader.all).to eq([])
      expect(reader.count).to eq(0)
    end

    it 'handles CSV with special characters' do
      csv_content = "id,name\n1,\"Client, with comma\"\n2,\"Client with \"\"quotes\"\"\""
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      results = reader.all
      expect(results.length).to eq(2)
      expect(results.first[:name]).to eq('Client, with comma')
      expect(results.second[:name]).to eq('Client with "quotes"')
    end
  end
end
