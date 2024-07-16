###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# spec/jobs/identify_external_clients_job_spec.rb

# spec/jobs/identify_external_clients_job_spec.rb

RSpec.describe IdentifyExternalClientsJob, type: :job do
  let(:inbox_s3) { instance_double('AwsS3') }
  let(:outbox_s3) { instance_double('AwsS3') }

  describe 'processing files' do
    let(:ghocid) { '456' }
    let(:csv_content) { "first_name,last_name,ssn4,dob,ghocid\nJohn,Doe,1234,1990-01-01,#{ghocid}" }
    let!(:client) { create(:hmis_hud_client, first_name: 'John', last_name: 'Doe', ssn: '1234', dob: '1990-01-01') }

    before do
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('text/csv')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(csv_content))
      allow(outbox_s3).to receive(:store)
      allow(inbox_s3).to receive(:delete)
    end

    it 'processes files from the inbox S3 and writes results to the outbox S3' do
      expect(outbox_s3).to receive(:store).with(hash_including(name: 'test-results.csv'))
      expect(inbox_s3).to receive(:delete).with(key: 'test.csv')

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
    end

    it 'matches clients based on SSN, DOB, and proper name' do
      expect(outbox_s3).to receive(:store).with(hash_including(name: 'test-results.csv'))
      expect(inbox_s3).to receive(:delete).with(key: 'test.csv')

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
    end

    it 'matches clients based on SSN, DOB, and proper name and verifies ghocid and client_id in the uploaded content' do
      expect(outbox_s3).to receive(:store) do |args|
        content = args[:content]
        csv = CSV.parse(content, headers: true)
        row = csv.first
        expect(row['GHOCID']).to eq(ghocid)
        expect(row['Client ID']).to eq(client.id.to_s)
      end

      expect(inbox_s3).to receive(:delete).with(key: 'test.csv')

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
    end

    it 'does not match clients if SSN, DOB, and proper name do not match' do
      non_matching_csv_content = "first_name,last_name,ssn4,dob,ghocid\nJane,Smith,5678,1985-05-05,2"
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(non_matching_csv_content))

      expect(outbox_s3).not_to receive(:store)
      expect(inbox_s3).not_to receive(:delete)

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
    end
  end

  describe 'error handling' do
    it 'logs an error for malformed CSV files' do
      malformed_csv_content = "first_name,last_name,ssn4,dob,ghocid\nJohn,Doe,\"1234,1990-01-01,1" # Unclosed quoted field
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('text/csv')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(malformed_csv_content))
      allow(Rails.logger).to receive(:error)

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
      expect(Rails.logger).to have_received(:error).with(/CSV parsing error/).once
    end

    it 'logs an error for invalid content type' do
      invalid_content_type = "first_name,last_name,ssn4,dob,ghocid\nJohn,Doe,1234,1990-01-01,1"
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('application/json')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(invalid_content_type))
      allow(Rails.logger).to receive(:error)

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
      expect(Rails.logger).to have_received(:error).with(/invalid content type/).once
    end
  end
end
