###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe IdentifyExternalClientsJob, type: :job do
  let(:inbox_s3) { instance_double('AwsS3') }
  let(:outbox_s3) { instance_double('AwsS3') }
  let(:external_id_field) { 'GHOCID' }

  describe 'processing files' do
    let(:first_name) { 'John' }
    let(:last_name) { 'Smith' }
    let(:dob) { '1990-01-01' }
    let(:ssn_last_four) { '1111' }
    let(:external_id) { '456' }
    let(:csv_content) do
      [
        "first_name,last_name,ssn4,dob,#{external_id_field}",
        [first_name, last_name, ssn_last_four, dob, external_id].join(','),
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
      ['all attributes match', 0, [{}]],
      ['name does not match', 0, [{ first_name: 'Eve' }]],
      ['ssn does not match', 0, [{ ssn: '111111234' }]],
      ['dob does not match', 0, [{ dob: '2002-02-02' }]],
      ['ssn does not match and name matches if transliterated', 0, [{ first_name: 'Jóhn', ssn: '111111234' }]],
      ['name and ssn does not match', nil, [{ first_name: 'Eve', ssn: '111111234' }]],
      ['name and dob does not match', nil, [{ first_name: 'Eve', dob: '2002-02-02' }]],
      ['dob and ssn does not match', nil, [{ dob: '2002-02-02', ssn: '111111234' }]],
      ['no attributes match', nil, [{ first_name: 'Eve', dob: '2002-02-02', ssn: '111111234' }]],
      ['two clients where all attributes match', 0, [{}, {}]],
      ['two clients where name does not match', 0, [{ first_name: 'Eve' }, { first_name: 'Eve' }]],
      ['second client is best match', 1, [{ first_name: 'Eve' }, {}]],
    ].each do |description, expected_match_idx, client_attrs|
      describe description do
        let(:source_data_source) { create :source_data_source }
        let(:default_client_attrs) do
          {
            first_name: first_name,
            last_name: last_name,
            ssn: "11111#{ssn_last_four}",
            dob: dob,
            data_source: source_data_source,
          }
        end
        let!(:clients) do
          client_attrs.map do |attrs|
            attrs = default_client_attrs.merge(attrs)
            create(:hmis_hud_client_with_warehouse_client, **attrs)
          end
        end
        if expected_match_idx
          it 'should match client to the CSV' do
            expect(outbox_s3).to receive(:store).with(hash_including(name: 'test-results.csv')) do |args|
              content = args[:content]
              csv = CSV.parse(content, headers: true)
              row = csv.first
              expect(row[external_id_field]).to eq(external_id)
              destination_id = clients[expected_match_idx].warehouse_client_source.destination_id
              expect(row['Client ID']).to eq(destination_id.to_s)
            end
            expect(inbox_s3).to receive(:delete).with(key: 'test.csv')

            described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3, external_id_field: external_id_field)
          end
        else
          it 'should not match the client to the CSV' do
            expect(outbox_s3).not_to receive(:store)
            expect(inbox_s3).not_to receive(:delete)

            described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3, external_id_field: external_id_field)
          end
        end
      end
    end
  end

  describe 'error handling' do
    it 'logs an error for malformed CSV files' do
      malformed_csv_content = "first_name,last_name,ssn4,dob,#{external_id_field}\nJohn,Doe,\"1234,1990-01-01,1" # Unclosed quoted field
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('text/csv')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(malformed_csv_content))
      allow(Rails.logger).to receive(:error)

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3, external_id_field: external_id_field)
      expect(Rails.logger).to have_received(:error).with(/CSV parsing error/).once
    end

    it 'logs an error for invalid content type' do
      invalid_content_type = "first_name,last_name,ssn4,dob,#{external_id_field}\nJohn,Doe,1234,1990-01-01,1"
      allow(inbox_s3).to receive(:list_objects).and_return([double(key: 'test.csv')])
      allow(inbox_s3).to receive(:get_file_type).and_return('application/json')
      allow(inbox_s3).to receive(:get_as_io).and_return(StringIO.new(invalid_content_type))
      allow(Rails.logger).to receive(:error)

      described_class.perform_now(inbox_s3: inbox_s3, outbox_s3: outbox_s3, external_id_field: external_id_field)
      expect(Rails.logger).to have_received(:error).with(/invalid content type/).once
    end
  end
end
