###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AdHocBatch, type: :model do
  before(:all) do
    GrdaWarehouse::Utility.clear!
  end

  after(:all) do
    GrdaWarehouse::Utility.clear!
  end

  describe 'validations' do
    it 'requires a description' do
      batch = described_class.new
      expect(batch).not_to be_valid
      expect(batch.errors[:description]).to include("can't be blank")
    end

    it 'requires a batch_file attachment on create' do
      batch = described_class.new(description: 'Test batch')
      expect(batch).not_to be_valid
      expect(batch.errors[:batch_file]).to include('must be attached')
    end

    it 'is valid with description and attached file' do
      batch = build(:ad_hoc_batch_valid)
      expect(batch).to be_valid
    end

    it 'allows updates to existing records without batch_file attachment' do
      # Create a record bypassing validation (simulating existing data)
      batch = described_class.new(description: 'Test batch')
      batch.save!(validate: false)

      # Should be able to update other fields without requiring batch_file
      batch.description = 'Updated description'
      expect(batch).to be_valid
      expect(batch.save).to be true
    end

    it 'validates file format for CSV files' do
      batch = described_class.new(description: 'Test batch')
      batch.batch_file.attach(
        io: StringIO.new('header1,header2\ndata1,data2'),
        filename: 'test.csv',
        content_type: 'text/csv',
      )
      expect(batch).to be_valid
    end

    it 'validates file format for Excel files' do
      batch = described_class.new(description: 'Test batch')
      batch.batch_file.attach(
        io: StringIO.new('fake excel content'),
        filename: 'test.xlsx',
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
      expect(batch).to be_valid
    end

    it 'accepts text/plain content type for CSV files' do
      batch = described_class.new(description: 'Test batch')
      batch.batch_file.attach(
        io: StringIO.new('header1,header2\ndata1,data2'),
        filename: 'test.csv',
        content_type: 'text/plain',
      )
      expect(batch).to be_valid
    end

    it 'rejects non-spreadsheet file formats' do
      batch = described_class.new(description: 'Test batch')
      batch.batch_file.attach(
        io: StringIO.new('fake image content'),
        filename: 'test.jpg',
        content_type: 'image/jpeg',
      )
      expect(batch).not_to be_valid
      expect(batch.errors[:batch_file]).to include('must be a CSV or Excel file')
    end
  end

  describe 'status' do
    let(:batch) { build(:ad_hoc_batch_valid) }

    context 'when import_errors are present' do
      it 'returns the import errors' do
        batch.import_errors = 'Some error occurred'
        expect(batch.status).to eq('Some error occurred')
      end
    end

    context 'when not started' do
      it 'returns Queued' do
        expect(batch.status).to eq('Queued')
      end
    end

    context 'when started but not completed' do
      before { batch.started_at = Time.current }

      it 'returns running status for recent start' do
        expect(batch.status).to include('Running since')
      end

      it 'returns Failed for old start' do
        batch.started_at = 25.hours.ago
        expect(batch.status).to eq('Failed')
      end
    end

    context 'when completed' do
      before do
        batch.started_at = 1.hour.ago
        batch.completed_at = Time.current
      end

      it 'returns Complete' do
        expect(batch.status).to eq('Complete')
      end
    end
  end

  describe '#sanitized_name' do
    let(:batch) { build(:ad_hoc_batch_valid) }

    it 'removes prohibited Excel worksheet characters' do
      batch.description = "Test*Name/With\\Problematic?Characters[]:'"
      expected = 'Test-Name-With-Problematic-Characters----'
      expect(batch.sanitized_name).to eq(expected)
    end
  end

  describe 'header validation' do
    it 'defines expected CSV headers' do
      expected_headers = ['First Name', 'Middle Name', 'Last Name', 'SSN', 'DOB']
      expect(described_class.csv_headers).to eq(expected_headers)
    end

    it 'defines header mapping' do
      expected_map = {
        first_name: 'First Name',
        middle_name: 'Middle Name',
        last_name: 'Last Name',
        ssn: 'SSN',
        dob: 'DOB',
      }
      expect(described_class.header_map).to eq(expected_map)
    end
  end

  describe '#csv method' do
    context 'with CSV file' do
      let(:batch) { create(:ad_hoc_batch_valid) }

      before do
        file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv')
        file = File.open(file_path, 'rb')
        batch.batch_file.attach(
          io: file,
          filename: 'initial_batch.csv',
          content_type: 'text/csv',
        )
        file.close
      end

      it 'parses CSV content correctly' do
        csv_data = batch.send(:csv)
        expect(csv_data).to be_an(Array)
        expect(csv_data.length).to eq(2)

        first_row = csv_data.first
        expect(first_row['First Name']).to eq('Faker')
        expect(first_row['Middle Name']).to eq('MFake')
        expect(first_row['Last Name']).to eq('Fakerson')
        expect(first_row['SSN']).to eq('123334444')
        expect(first_row['DOB']).to eq('2010-12-01')
      end

      it 'extracts headers correctly' do
        batch.send(:csv) # Force header calculation
        headers = batch.send(:headers_from_csv)
        expected_headers = ['First Name', 'Middle Name', 'Last Name', 'SSN', 'DOB']
        expect(headers).to eq(expected_headers)
      end
    end

    context 'with Excel file' do
      let(:batch) { create(:ad_hoc_batch_valid_excel) }

      it 'parses Excel content correctly' do
        csv_data = batch.send(:csv)
        expect(csv_data).to be_an(Array)
        expect(csv_data.length).to eq(2)

        first_row = csv_data.first
        expect(first_row['First Name']).to eq('Faker')
        expect(first_row['Middle Name']).to eq('MFake')
        expect(first_row['Last Name']).to eq('Fakerson')
        expect(first_row['SSN']).to eq('123334444')
        expect(first_row['DOB']).to eq('2010-12-01')
      end

      it 'extracts headers correctly from Excel' do
        batch.send(:csv) # Force header calculation
        headers = batch.send(:headers_from_csv)
        expected_headers = ['First Name', 'Middle Name', 'Last Name', 'SSN', 'DOB']
        expect(headers).to eq(expected_headers)
      end
    end

    context 'without attached file' do
      let(:batch) { described_class.new(description: 'Test batch') }

      it 'returns nil when no file is attached' do
        expect(batch.send(:csv)).to be_nil
      end
    end

    context 'with invalid Excel file' do
      let(:batch) { create(:ad_hoc_batch_valid) }

      before do
        # Attach a file with corrupted/empty Excel content
        batch.batch_file.attach(
          io: StringIO.new(''),
          filename: 'empty.xlsx',
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      end

      it 'handles corrupted Excel files gracefully' do
        # Since the Roo gem throws an exception for invalid Excel files,
        # we expect an exception to be raised
        expect { batch.send(:csv) }.to raise_error(Zip::Error)
      end
    end
  end

  describe '#process! integration tests' do
    let(:data_source) { create(:ad_hoc_data_source) }

    context 'with valid CSV file' do
      let(:batch) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source) }

      before do
        file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv')
        file = File.open(file_path, 'rb')
        batch.batch_file.attach(
          io: file,
          filename: 'initial_batch.csv',
          content_type: 'text/csv',
        )
        file.close
      end

      it 'processes successfully' do
        expect { batch.process! }.to change { batch.reload.completed_at }.from(nil)
        expect(batch.import_errors).to be_blank
        expect(batch.started_at).to be_present
        expect(batch.completed_at).to be_present
        expect(batch.uploaded_count).to eq(2)
        expect(batch.ad_hoc_clients.count).to eq(2)
      end

      it 'creates ad_hoc_clients with correct data' do
        batch.process!

        client = batch.ad_hoc_clients.first
        expect(client.first_name).to eq('Faker')
        expect(client.middle_name).to eq('MFake')
        expect(client.last_name).to eq('Fakerson')
        expect(client.ssn).to eq('123334444')
        expect(client.dob).to eq(Date.parse('2010-12-01'))
      end
    end

    context 'with valid Excel file' do
      let(:batch) { create(:ad_hoc_batch_valid_excel, ad_hoc_data_source: data_source) }

      it 'processes Excel files successfully' do
        expect { batch.process! }.to change { batch.reload.completed_at }.from(nil)
        expect(batch.import_errors).to be_blank
        expect(batch.started_at).to be_present
        expect(batch.completed_at).to be_present
        expect(batch.uploaded_count).to eq(2)
        expect(batch.ad_hoc_clients.count).to eq(2)
      end

      it 'creates ad_hoc_clients with correct data from Excel' do
        batch.process!

        client = batch.ad_hoc_clients.first
        expect(client.first_name).to eq('Faker')
        expect(client.middle_name).to eq('MFake')
        expect(client.last_name).to eq('Fakerson')
        expect(client.ssn).to eq('123334444')
        expect(client.dob).to eq(Date.parse('2010-12-01'))
      end
    end

    context 'with invalid CSV headers' do
      let(:batch) { create(:ad_hoc_batch_invalid, ad_hoc_data_source: data_source) }

      before do
        file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/invalid_batch.csv')
        file = File.open(file_path, 'rb')
        batch.batch_file.attach(
          io: file,
          filename: 'invalid_batch.csv',
          content_type: 'text/csv',
        )
        file.close
      end

      it 'sets import errors for invalid headers' do
        batch.process!

        expect(batch.import_errors).to include('Headers do not match expected headers')
        expect(batch.import_errors).to include('First Name,Middle Name,Last Name,SSN,DOB')
        expect(batch.import_errors).to include('Best Name,Middle Name,Last Name,SSN,DOB')
        expect(batch.ad_hoc_clients.count).to eq(0)
      end
    end

    context 'with invalid Excel headers' do
      let(:batch) { create(:ad_hoc_batch_invalid_excel, ad_hoc_data_source: data_source) }

      it 'sets import errors for invalid Excel headers' do
        batch.process!

        expect(batch.import_errors).to include('Headers do not match expected headers')
        expect(batch.import_errors).to include('First Name,Middle Name,Last Name,SSN,DOB')
        expect(batch.import_errors).to include('Best Name,Middle Name,Last Name,SSN,DOB')
        expect(batch.ad_hoc_clients.count).to eq(0)
      end
    end
  end

  describe '.process!' do
    let(:data_source) { create(:ad_hoc_data_source) }
    let!(:batch1) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source) }
    let!(:batch2) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source) }
    let!(:started_batch) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source, started_at: 1.hour.ago) }

    before do
      # Attach files to the unstarted batches
      [batch1, batch2].each do |batch|
        file_path = Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv')
        file = File.open(file_path, 'rb')
        batch.batch_file.attach(
          io: file,
          filename: 'initial_batch.csv',
          content_type: 'text/csv',
        )
        file.close
      end
    end

    it 'processes only unstarted batches' do
      described_class.process!

      expect(batch1.reload.completed_at).to be_present
      expect(batch2.reload.completed_at).to be_present
      expect(started_batch.reload.completed_at).to be_blank # Should not be reprocessed
    end
  end
end
