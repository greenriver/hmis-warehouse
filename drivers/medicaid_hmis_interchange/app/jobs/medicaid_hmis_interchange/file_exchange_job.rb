###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'net/sftp'

module MedicaidHmisInterchange
  class FileExchangeJob < ::BaseJob
    def perform
      file_list = fetch_file_list
      if file_list.empty?
        deliver_submission
        touch_trigger_file
      else
        response = find_response(file_list)
        if response.present?
          response.process_response

          deliver_submission
          touch_trigger_file
        end
      end
    end

    private def fetch_file_list
      directory = sftp_credentials[:path]
      results = []
      using_sftp do |sftp|
        sftp.dir.glob(directory, '*').each do |remote|
          next unless remote.name.match?(/.*rdc_homeless.*/)

          results << File.join(directory, remote.name)
        end
      end

      results
    end

    private def find_response(file_list)
      most_recent_upload = MedicaidHmisInterchange::Health::Submission.last
      response_path = File.join(sftp_credentials[:path], most_recent_upload.generate_filename(prefix: 'err_', suffix: '_details'))
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

    private def deliver_submission
      submission = MedicaidHmisInterchange::Health::Submission.new
      zip_path = submission.run_and_save!(sftp_credentials[:data_source_name])
      using_sftp do |sftp|
        sftp.upload!(zip_path, File.join(sftp_credentials[:path], submission.generate_filename(extension: 'zip')))
      end
    ensure
      submission.remove_export_directory
    end

    private def touch_trigger_file
      using_sftp do |sftp|
        sftp.upload!('/dev/null', File.join(sftp_credentials[:path], 'rdc_homeless_done.txt'))
      end
    end

    private def sftp_credentials
      @sftp_credentials ||= ::Health::ImportConfig.find_by(kind: :medicaid_hmis_exchange) || {}
    end

    private def using_sftp
      credentials = sftp_credentials
      Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        password: credentials['password'] || credentials.password,
        auth_methods: ['publickey', 'password'],
        keepalive: true,
        keepalive_interval: 60,
      ) do |connection|
        yield connection
      end
    end
  end
end
