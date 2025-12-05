# frozen_string_literal: true

require 'rails_helper'
require 'csv'
require 'tempfile'

# The class is defined in the Rake task file
require_relative '../../../../lib/tasks/activity_logs'

RSpec.describe Hmis::ActivityLogs::Correlator do
  include_context 'hmis base setup'
  include_context 'file upload setup'
  let(:tenant) { 'test-client' }
  let(:timestamp) { Time.zone.now }
  let!(:csv_file) { Tempfile.new(['logs', '.csv']) }
  let(:csv_path) { csv_file.path }
  let!(:client) { create(:hmis_hud_client, data_source: ds1, user: u1) }
  let!(:client_file) do
    create(:file, client: client, blob: blob, name: 'xyz', confidential: false, user: hmis_user)
  end

  subject(:correlator) { described_class.new(csv_path: csv_path, tenant: tenant) }

  after do
    csv_file.close
    csv_file.unlink
  end

  def write_csv(rows)
    CSV.open(csv_path, 'w', headers: ['@timestamp', '@message'], write_headers: true) do |csv|
      rows.each { |row| csv << row }
    end
    csv_file.rewind
  end

  def log_message(path, overrides = {})
    {
      tenant: tenant,
      path: path,
      status: 302,
      location: 'https://client-hmis-production-files.s3.amazonaws.com/test',
      controller: 'ActiveStorage::Blobs::RedirectController',
      action: 'show',
      method: 'GET',
    }.merge(overrides.symbolize_keys).to_json
  end

  def file_access_path(signed_id)
    "/rails/active_storage/blobs/redirect/#{signed_id}/test.txt"
  end

  context 'when a log entry matches a database record' do
    let(:path) { file_access_path(blob.signed_id) }

    context 'when header_client_id is present' do
      let(:other_client) { create(:hmis_hud_client, data_source: ds1, user: u1) }

      before do
        create(
          :hmis_activity_log,
          created_at: timestamp,
          operation_name: 'GetEnrollmentDetails',
          variables: { 'id' => other_client.id },
          header_client_id: client.id,
        )
        write_csv([[timestamp.iso8601(3), log_message(path)]])
      end

      it 'correlates the log entry successfully' do
        correlator.run
        expect(correlator.matched).to eq(1)
        expect(correlator.unmatched_rows).to be_empty
        expect(correlator.total_considered).to eq(1)
      end
    end

    context 'when correlation falls back to GraphQL variables' do
      before do
        create(
          :hmis_activity_log,
          created_at: timestamp,
          operation_name: 'GetClient',
          variables: { 'id' => client.id },
          header_client_id: nil,
          header_enrollment_id: nil,
        )
        write_csv([[timestamp.iso8601(3), log_message(path)]])
      end

      it 'correlates the log entry successfully' do
        correlator.run
        expect(correlator.matched).to eq(1)
        expect(correlator.unmatched_rows).to be_empty
        expect(correlator.total_considered).to eq(1)
      end
    end
  end

  context 'when a log entry references a file' do
    let(:path) { file_access_path(blob.signed_id) }

    before do
      create(
        :hmis_activity_log,
        created_at: timestamp,
        operation_name: 'GetFile',
        variables: { 'id' => client_file.id },
      )
      write_csv([[timestamp.iso8601(3), log_message(path)]])
    end

    it 'correlates the log entry successfully' do
      correlator.run
      expect(correlator.matched).to eq(1)
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(1)
    end
  end

  context 'when a log entry references an enrollment' do
    let(:path) { file_access_path(blob.signed_id) }
    let!(:enrollment) do
      create(
        :hmis_hud_enrollment,
        data_source: ds1,
        user: u1,
        project: p1,
        client: client,
      )
    end

    context 'when header_enrollment_id is present' do
      before do
        create(
          :hmis_activity_log,
          created_at: timestamp,
          operation_name: 'GetClient',
          variables: { 'id' => client.id },
          header_enrollment_id: enrollment.id,
        )
        write_csv([[timestamp.iso8601(3), log_message(path)]])
      end

      it 'uses the header enrollment to correlate' do
        correlator.run
        expect(correlator.matched).to eq(1)
        expect(correlator.unmatched_rows).to be_empty
        expect(correlator.total_considered).to eq(1)
      end
    end

    context 'when correlation falls back to enrollment lookup' do
      before do
        create(
          :hmis_activity_log,
          created_at: timestamp,
          operation_name: 'GetEnrollmentDetails',
          variables: { 'id' => enrollment.id },
        )
        write_csv([[timestamp.iso8601(3), log_message(path)]])
      end

      it 'correlates via the enrollment lookup path' do
        correlator.run
        expect(correlator.matched).to eq(1)
        expect(correlator.unmatched_rows).to be_empty
        expect(correlator.total_considered).to eq(1)
      end
    end
  end

  context 'when a log entry does not match any database record' do
    let(:path) { file_access_path(blob.signed_id) }
    let(:message) { log_message(path) }
    let(:timestamp_str) { timestamp.iso8601(3) }

    it 'records the message as unmatched if no activity log exists' do
      write_csv([[timestamp_str, message]])
      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to eq([[timestamp_str, message]])
      expect(correlator.total_considered).to eq(1)
    end

    it 'records the message as unmatched if activity log is for a different client' do
      other_client = create(:hmis_hud_client)
      create(:hmis_activity_log,
             created_at: timestamp,
             operation_name: 'GetClient',
             variables: { 'id' => other_client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to eq([[timestamp_str, message]])
    end

    it 'records the message as unmatched if activity log is outside the time window' do
      create(:hmis_activity_log,
             created_at: timestamp - 6.minutes,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to eq([[timestamp_str, message]])
    end

    it 'records the message as unmatched if activity log occurs too far after blob access' do
      create(:hmis_activity_log,
             created_at: timestamp + 15.seconds,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to eq([[timestamp_str, message]])
    end
  end

  context 'time window boundaries' do
    let(:path) { file_access_path(blob.signed_id) }
    let(:message) { log_message(path) }
    let(:timestamp_str) { timestamp.iso8601(3) }

    it 'matches activity logs within the forward tolerance window' do
      create(:hmis_activity_log,
             created_at: timestamp + 8.seconds,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(1)
      expect(correlator.unmatched_rows).to be_empty
    end

    it 'matches activity logs at the edge of backward tolerance' do
      create(:hmis_activity_log,
             created_at: timestamp - 59.seconds,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(1)
      expect(correlator.unmatched_rows).to be_empty
    end

    it 'does not match activity logs just outside backward tolerance' do
      create(:hmis_activity_log,
             created_at: timestamp - 301.seconds,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to eq([[timestamp_str, message]])
    end

    it 'matches the first activity log within window when multiple exist' do
      # Create multiple activity logs for the same client
      create(:hmis_activity_log,
             created_at: timestamp - 30.seconds,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      create(:hmis_activity_log,
             created_at: timestamp - 10.seconds,
             operation_name: 'GetClientFiles',
             variables: { 'id' => client.id })
      write_csv([[timestamp_str, message]])

      correlator.run
      expect(correlator.matched).to eq(1)
      expect(correlator.unmatched_rows).to be_empty
    end
  end

  context 'when log entry is for another tenant' do
    let(:path) { file_access_path(blob.signed_id) }
    let(:message) { { tenant: 'another-tenant', path: path }.to_json }

    before do
      create(:hmis_activity_log,
             created_at: timestamp,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })
      write_csv([[timestamp.iso8601(3), message]])
    end

    it 'does not consider the log entry' do
      correlator.run
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(0)
    end
  end

  context 'with invalid data' do
    let(:path) { file_access_path(blob.signed_id) }

    it 'skips rows without a message' do
      write_csv([[timestamp.iso8601(3), nil]])
      correlator.run
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows with invalid JSON' do
      write_csv([[timestamp.iso8601(3), 'not json']])
      correlator.run
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows without a path' do
      message = { tenant: tenant }.to_json
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows with an invalid timestamp' do
      message = log_message(path)
      write_csv([['invalid-date', message]])
      correlator.run
      expect(correlator.unmatched_rows).to be_empty
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows with an invalid signed_id' do
      path = file_access_path('invalid-id')
      message = log_message(path)
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(1)
      expect(correlator.matched).to eq(0)
      expect(correlator.unmatched_rows.size).to eq(1)
    end
  end

  context 'with a mix of valid and invalid data' do
    let!(:other_client) { create(:hmis_hud_client, data_source: ds1, user: u1) }
    let!(:other_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('other test data' * 10),
        filename: 'other_test.txt',
        content_type: 'text/plain',
      )
    end
    let!(:other_client_file) { create(:file, client: other_client, blob: other_blob, user: hmis_user) }
    let(:matched_path) { file_access_path(blob.signed_id) }
    let(:unmatched_path) { file_access_path(other_blob.signed_id) }
    let(:unmatched_message) { log_message(unmatched_path) }
    let(:unmatched_row) { [timestamp.iso8601(3), unmatched_message] }

    before do
      # Log for the matched client
      create(:hmis_activity_log,
             created_at: timestamp,
             operation_name: 'GetClient',
             variables: { 'id' => client.id })

      rows = [
        [timestamp.iso8601(3), log_message(matched_path)], # match
        unmatched_row, # no db record for other_client
        [timestamp.iso8601(3), { tenant: 'other-tenant', path: 'any' }.to_json], # other tenant
        [timestamp.iso8601(3), 'not json'], # invalid json
        [timestamp.iso8601(3), { tenant: tenant }.to_json], # no path
      ]
      write_csv(rows)
    end

    it 'correctly processes all rows' do
      correlator.run
      expect(correlator.matched).to eq(1)
      expect(correlator.unmatched_rows).to eq([unmatched_row])
      expect(correlator.total_considered).to eq(2)
    end
  end

  context 'with invalid controller/action/method' do
    let(:path) { file_access_path(blob.signed_id) }

    it 'skips rows with wrong controller' do
      message = log_message(path, 'controller' => 'SomeOtherController')
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows with wrong action' do
      message = log_message(path, 'action' => 'create')
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(0)
    end

    it 'tracks suspicious non-GET requests' do
      message = log_message(path, 'method' => 'POST')
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(0)
      expect(correlator.suspicious_rows.size).to eq(1)
      expect(correlator.suspicious_rows.first).to include('Non-GET method')
    end
  end

  context 'with missing location or non-302 status' do
    let(:path) { file_access_path(blob.signed_id) }

    it 'skips rows without location header' do
      message = log_message(path, 'location' => nil)
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(0)
    end

    it 'skips rows with non-302 status' do
      message = log_message(path, 'status' => 200)
      write_csv([[timestamp.iso8601(3), message]])
      correlator.run
      expect(correlator.total_considered).to eq(0)
    end
  end
end
