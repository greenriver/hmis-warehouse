# frozen_string_literal: true

require 'csv'
require 'json'

# Correlates Active Storage access logs from a CSV file with Hmis::ActivityLog entries.
# This class encapsulates the logic for parsing the CSV, filtering logs, and matching them against database records.
module Hmis
  module ActivityLogs
    class Correlator
      attr_reader :total_considered, :matched, :unmatched_rows, :suspicious_rows, :invalid_signed_ids

      def initialize(csv_path:, tenant:, tolerance_seconds: 60)
        @csv_path = csv_path
        @tenant = tenant
        @tolerance_seconds = tolerance_seconds.to_i
        @total_considered = 0
        @matched = 0
        @unmatched_rows = []
        @suspicious_rows = []
        @invalid_signed_ids = 0
      end

      def run
        CSV.foreach(@csv_path, headers: true) do |row|
          process_row(row)
        end
      end

      def emit_csv(file)
        CSV(file) do |csv|
          csv << ['@timestamp', '@message']
          unmatched_rows.each do |row|
            csv << row
          end
        end
      end

      private

      def process_row(row)
        timestamp_raw, message_raw = row.values_at('@timestamp', '@message')

        return unless timestamp_raw.present? && message_raw.present?

        payload = parse_payload(message_raw)
        return if payload.blank?
        return unless payload['tenant'].blank? || payload['tenant'] == @tenant

        # Validate this is an ActiveStorage blob redirect request
        return unless payload['controller'] == 'ActiveStorage::Blobs::RedirectController'
        return unless payload['action'] == 'show'

        # Track suspicious non-GET requests on blob URLs
        if payload['method'] != 'GET'
          @suspicious_rows << [timestamp_raw, message_raw, 'Non-GET method']
          return
        end

        # Only process successful S3 redirects (status 302 with location header)
        return unless payload['status'] == 302 && payload['location'].present?

        path = payload['path'].presence
        return unless path

        timestamp = parse_timestamp(timestamp_raw)
        return unless timestamp

        @total_considered += 1

        found = find_matches(timestamp: timestamp, path: path)
        if found.present?
          @matched += 1
        else
          @unmatched_rows << [timestamp_raw, message_raw]
        end
      end

      def parse_payload(message_raw)
        JSON.parse(message_raw)
      rescue JSON::ParserError
        nil
      end

      def parse_timestamp(timestamp_raw)
        Time.parse(timestamp_raw).in_time_zone
      rescue ArgumentError
        nil
      end

      def get_files_from_name(path)
        encoded_filename = path.split('/').last
        decoded = CGI.unescape(encoded_filename)
        files = Hmis::File.with_deleted.order(:id).where(name: decoded).limit(2)

        if files.size > 1
          raise "found more than 1 files named #{decoded.inspect}"
          return nil
        end
        files
      end

      def get_file_from_path(path)
        # The path is expected to be in the format:
        # /rails/active_storage/blobs/redirect/<signed_id>/<filename>
        # The regex below extracts the signed_id.
        signed_id = path.match(/\/blobs\/redirect\/([^\/]+)\//)&.captures&.first
        return unless signed_id.present?

        blob = ActiveStorage::Blob.find_signed(signed_id)
        return unless blob

        # This logic assumes a blob is only ever attached to one record,
        # or that the first attachment is always the correct one.
        attachment = blob.attachments.first
        return unless attachment&.record_type.in?(['Hmis::File', 'GrdaWarehouse::ClientFile', 'GrdaWarehouse::File'])

        # Use unscoped to include soft-deleted files
        Hmis::File.with_deleted.find_by(id: attachment.record_id)
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        @invalid_signed_ids += 1
        nil
      end

      def client_id_from_log_record(record)
        # Priority: explicit client header -> header enrollment -> file lookup -> variables
        return record.header_client_id if record.header_client_id.present?

        ids = extract_ids(record)

        client_id_from_enrollment(record.header_enrollment_id) ||
          client_id_from_file(ids[:file_id]) ||
          ids[:client_id] ||
          client_id_from_enrollment(ids[:enrollment_id])
      end

      def client_id_from_file(file_id)
        return unless file_id

        Hmis::File.with_deleted.find_by(id: file_id)&.client_id
      end

      def client_id_from_enrollment(enrollment_id)
        return unless enrollment_id

        enrollment = Hmis::Hud::Enrollment.
          with_deleted.
          includes(:client_including_deleted, :client).
          find_by(id: enrollment_id)

        enrollment&.client_including_deleted&.id || enrollment&.client&.id
      end

      def extract_ids(record)
        variables = record.variables || {}

        case record.operation_name
        when 'GetEnrollmentDetails', 'GetEnrollment', 'GetEnrollmentAssessments'
          { enrollment_id: variables['id'] }
        when 'SubmitAssessment'
          { enrollment_id: variables.dig('input', 'input', 'enrollmentId') }
        when 'GetFile'
          { file_id: variables['id'] }
        when 'GetClient', 'GetClientImage', 'GetClientFiles', 'GetClientEnrollments'
          { client_id: variables['id'] }
        else
          {}
        end
      end

      def find_matches(timestamp:, path:)
        # earliest log entries are 11/27/2023

        # Extract client_id from the CloudWatch path once, before searching activity logs
        path_file = get_file_from_path(path)
        path_files = []
        if path_file
          path_files = [path_file]
        else
          path_files = get_files_from_name(path)
        end

        return if path_files.blank?

        # Find the GraphQL request occurring before the Active Storage access. Add 10 second allowance for clock skew
        window = (timestamp - @tolerance_seconds.seconds)..(timestamp + 10.seconds)
        activity_log_scope = Hmis::ActivityLog.where(created_at: window)

        # first try and locate the log using file id
        resolved_object_ids = path_files.map  { |f| "File/#{f.id}" }
        activity_log_scope.where.not(resolved_fields: nil).find_each do |record|
          return record if (resolved_object_ids & record.resolved_fields.keys).any?
        end

        return # skipping

        path_client_id = path_file&.client_id
        return unless path_client_id

        # try and locate the log using client id
        activity_log_scope.find_each do |record|
          log_client_id = client_id_from_log_record(record)
          next unless log_client_id

          return record if log_client_id == path_client_id
        end
        nil
      end
    end
  end
end
