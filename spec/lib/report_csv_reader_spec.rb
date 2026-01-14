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

  describe '#batch_read' do
    it 'yields nothing when no file is attached' do
      batches = []
      reader.batch_read { |batch| batches << batch }
      expect(batches).to eq([])
    end

    it 'yields batches of rows' do
      csv_content = "id,name,age\n1,Client 1,25\n2,Client 2,30"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read { |batch| batches << batch }
      expect(batches.length).to eq(1)
      expect(batches.first.length).to eq(2)
      expect(batches.first.first[:id]).to eq('1')
      expect(batches.first.first[:name]).to eq('Client 1')
      expect(batches.first.first[:age]).to eq('25')
    end

    it 'uses symbol keys for headers' do
      csv_content = "id,name\n1,Client 1"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read { |batch| batches << batch }
      # We now use symbol keys consistently
      expect(batches.first.first.keys).to all(be_a(Symbol))
      expect(batches.first.first.keys).to contain_exactly(:id, :name)
      expect(batches.first.first[:id]).to eq('1')
      expect(batches.first.first[:name]).to eq('Client 1')
    end

    it 'respects custom batch size' do
      csv_content = "id,name\n" + (1..10).map { |i| "#{i},Client #{i}" }.join("\n")
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read(batch_size: 3) { |batch| batches << batch }
      expect(batches.length).to eq(4) # 3, 3, 3, 1
      expect(batches[0].length).to eq(3)
      expect(batches[1].length).to eq(3)
      expect(batches[2].length).to eq(3)
      expect(batches[3].length).to eq(1)
    end

    it 'handles exact multiple of batch size' do
      csv_content = "id,name\n" + (1..6).map { |i| "#{i},Client #{i}" }.join("\n")
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read(batch_size: 3) { |batch| batches << batch }
      expect(batches.length).to eq(2) # 3, 3
      expect(batches[0].length).to eq(3)
      expect(batches[1].length).to eq(3)
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

  describe 'edge cases' do
    it 'handles empty CSV file' do
      csv_content = ''
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read { |batch| batches << batch }
      expect(batches).to eq([])
      expect(reader.count).to eq(0)
    end

    it 'handles CSV with only headers' do
      csv_content = "id,name\n"
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read { |batch| batches << batch }
      expect(batches).to eq([])
      expect(reader.count).to eq(0)
    end

    it 'handles CSV with special characters' do
      csv_content = "id,name\n1,\"Client, with comma\"\n2,\"Client with \"\"quotes\"\"\""
      report.clients_csv.attach(
        io: StringIO.new(csv_content),
        filename: 'clients.csv',
        content_type: 'text/csv',
      )

      batches = []
      reader.batch_read { |batch| batches << batch }
      expect(batches.length).to eq(1)
      expect(batches.first.length).to eq(2)
      expect(batches.first.first[:name]).to eq('Client, with comma')
      expect(batches.first.second[:name]).to eq('Client with "quotes"')
    end
  end
end
