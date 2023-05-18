###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/sftp'
module MedicaidHmisInterchange
  class FileExchangeJob < ::BaseJob
    INBOUND_SUB_PATH = 'from_ehs'
    OUTBOUND_SUB_PATH = 'to_ehs'
    def perform(test_file: false, test_file_version: nil)
      # Don't run, if not configured.
      return unless sftp_credentials

      sent_files = fetch_file_list(OUTBOUND_SUB_PATH)
      received_files = fetch_file_list(INBOUND_SUB_PATH)
      if sent_files.empty?
        deliver_submission(test_file: test_file, test_file_version: test_file_version)
        touch_trigger_file
      else
        response = find_response(received_files)
        if response.present?
          response.process_response

          deliver_submission(test_file: test_file, test_file_version: test_file_version)
          touch_trigger_file
        end
      end
    end

    private def fetch_file_list(sub_path)
      directory = sftp_credentials[:path]
      results = []
      using_sftp do |sftp|
        # Always check in the `from_ehs` sub-directory for the response
        sftp.dir.glob("#{directory}/#{sub_path}", '*').each do |remote|
          next unless remote.name.match?(/.*rdc_homeless.*/)

          results << File.join(directory, sub_path, remote.name)
        end
      end

      results
    end

    private def find_response(file_list)
      most_recent_upload = MedicaidHmisInterchange::Health::Submission.last
      response_path = File.join(sftp_credentials[:path], INBOUND_SUB_PATH, most_recent_upload.response_filename)
      return nil unless file_list.detect { |name| name == response_path }

      Tempfile.create(File.basename(response_path)) do |tmpfile|
        using_sftp do |sftp|
          sftp.download!(response_path, tmpfile.path)
          return MedicaidHmisInterchange::Health::Response.create(
            submission_id: most_recent_upload.id,
            error_report: tmpfile.read,
          )
        end
      end
    end

    private def deliver_submission(test_file: false, test_file_version: nil)
      submission = MedicaidHmisInterchange::Health::Submission.new(test_file: test_file, test_file_version: test_file_version)
      zip_path = submission.run_and_save!(sftp_credentials[:data_source_name])
      using_sftp do |sftp|
        sftp.upload!(zip_path, File.join("#{sftp_credentials[:path]}/#{OUTBOUND_SUB_PATH}", submission.zip_filename))
      end
    ensure
      submission.remove_export_directory
    end

    private def touch_trigger_file
      using_sftp do |sftp|
        sftp.upload!('/dev/null', File.join("#{sftp_credentials[:path]}/#{OUTBOUND_SUB_PATH}", 'rdc_homeless_done.txt'))
      end
    end

    def self.sftp_credentials
      ::Health::ImportConfig.find_by(kind: :medicaid_hmis_exchange)
    end

    private def sftp_credentials
      @sftp_credentials ||= self.class.sftp_credentials
    end

    private def using_sftp
      credentials = sftp_credentials
      file = Tempfile.new('mhx_private_key')
      opts = {
        keepalive: true,
        keepalive_interval: 60,
      }
      if Rails.env.production? || Rails.env.staging?
        key = credentials['password'] || credentials.password
        file.write(key)
        file.rewind
        file.close
        opts.merge!(
          {
            keys: [file.path],
            keys_only: true,
          },
        )

      else
        opts.merge!(
          {
            password: credentials['password'] || credentials.password,
            auth_methods: ['publickey', 'password'],
          },
        )
      end

      Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        **opts,
      ) do |connection|
        yield connection
      end
      file.unlink
    end
  end
end
