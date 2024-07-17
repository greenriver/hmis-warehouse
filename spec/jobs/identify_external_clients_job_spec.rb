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
    let(:first_name) { 'John' }
    let(:last_name) { 'Smith' }
    let(:dob) { '1990-01-01' }
    let(:ssn_last_four) { '1111' }
    let(:ghocid) { '456' }
    let(:csv_content) do
      [
        'first_name,last_name,ssn4,dob,ghocid',
        [first_name, last_name, ssn_last_four, dob, ghocid].join(','),
      ].join("\n")
    end

    before do
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('text/csv')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(csv_content))
      allow(outbox_s3).to receive(:store)
      allow(inbox_s3).to receive(:delete)
    end

    [
      [true, {}],
      [true, { first_name: 'Eve' }],
      [true, { ssn: '111111234' }],
      [true, { dob: '2002-02-02' }],
      [true, { first_name: 'Jóhn', ssn: '111111234' }],
      [false, { first_name: 'Eve', ssn: '111111234' }],
      [false, { first_name: 'Eve', dob: '2002-02-02' }],
      [false, { dob: '2002-02-02', ssn: '111111234' }],
      [false, { first_name: 'Eve', dob: '2002-02-02', ssn: '111111234' }],
    ].each do |expected_match, client_attrs|
      describe "with client attrs: #{client_attrs.inspect}" do
        let!(:client) do
          default_attrs = {
            first_name: first_name,
            last_name: last_name,
            ssn: "11111#{ssn_last_four}",
            dob: dob,
          }
          create(:hmis_hud_client, **default_attrs.merge(client_attrs))
        end
        if expected_match
          it 'matches client to the CSV' do
            expect(outbox_s3).to receive(:store).with(hash_including(name: 'test-results.csv')) do |args|
              content = args[:content]
              csv = CSV.parse(content, headers: true)
              row = csv.first
              expect(row['GHOCID']).to eq(ghocid)
              expect(row['Client ID']).to eq(client.id.to_s)
            end
            expect(inbox_s3).to receive(:delete).with(key: 'test.csv')

            described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
          end
        else
          it 'does not match the client to the CSV' do
            expect(outbox_s3).not_to receive(:store)
            expect(inbox_s3).not_to receive(:delete)

            described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3)
          end
        end
      end
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
