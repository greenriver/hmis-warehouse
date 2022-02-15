###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'open3'
require 'tempfile'

module Glacier
  class Restore < AwsService
    attr_accessor :archive, :vault, :_client, :download_path, :processing_cmd

    delegate :job_id, to: :archive
    delegate :name, to: :vault, prefix: true

    SPIN_TIME_S = 5.minutes.to_i

    TIER = ENV.fetch('GLACIER_JOB_TIER') { "Expedited" }
    #TIER = "Standard" # much slower but cheaper

    def initialize(archive_id:, download_path: nil, processing_cmd: nil)
      # Find by either our primary key or the ID Amazon knows it by.
      self.archive        = Archive.where(id: archive_id).first || Archive.find_by(archive_id: archive_id)
      self.vault          = archive.vault
      self.download_path  = download_path
      self.processing_cmd = processing_cmd
      self._client = if ENV.fetch('GLACIER_AWS_SECRET_ACCESS_KEY').present? && ENV.fetch('GLACIER_AWS_SECRET_ACCESS_KEY') != 'unknown'
        Aws::Glacier::Client.new({
          region: 'us-east-1',
          credentials: Aws::Credentials.new(
            ENV.fetch('GLACIER_AWS_ACCESS_KEY_ID'),
            ENV.fetch('GLACIER_AWS_SECRET_ACCESS_KEY')
          )
        })
      else
        Aws::Glacier::Client.new({
          region: 'us-east-1',
        })
      end

      no_output   = self.download_path.blank? && self.processing_cmd.blank?
      two_outputs = self.download_path.present? && self.processing_cmd.present?

      if no_output || two_outputs
        raise "You need either a download path or a command to process the stream of data"
      end
    end

    def run!
      initiate_job!
      wait!

      if self.download_path.present?
        download_to_file!
      elsif self.processing_cmd.present?
        stream_to_command!
      end
    end

    def clear_existing_job!
      self.archive.update_attribute(:job_id, nil)
    end

    private

    def initiate_job!
      return if job_id.present?

      # https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html
      resp = _client.initiate_job({
        job_parameters: {
          description: "Archive retreival from #{vault_name} for ID #{archive.id}",
          archive_id: archive.archive_id,
          tier: TIER,
          type: "archive-retrieval",
        },
        vault_name: vault_name,
      })

      self.archive.update_attribute(:job_id, resp.job_id)

      Rails.logger.info "Initiated a retrieval job #{resp.job_id}"
      Rails.logger.info "You can safely exit and rerun the retrieval code to wait on the job later. It won't create a new job."
    end

    # This is very slow
    def wait!
      job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      while(job.status_code == "InProgress")
        Rails.logger.info "sleeping for #{SPIN_TIME_S} seconds"
        sleep SPIN_TIME_S
        job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      end
    end

    def download_to_file!
      Rails.logger.info "Downloading the archive to #{self.download_path}"

      self.processing_cmd = "cat > #{self.download_path}"
      stream_to_command!
    end

    def stream_to_command!
      Rails.logger.info "Streaming the archive to #{self.processing_cmd}"

      chunk = 32.megabytes # for testing -> 200.kilobytes
      start_byte = 0

      next_end_byte = -> {
        if (start_byte + chunk) >= self.archive.size_in_bytes
          self.archive.size_in_bytes - 1
        else
          start_byte + chunk - 1
        end
      }

      end_byte = next_end_byte.call

      Open3.popen2(self.processing_cmd) do |cmd_stdin, cmd_stdout, wait_thread|
        while (start_byte != self.archive.size_in_bytes) do
          byte_range = "bytes=#{start_byte}-#{end_byte}"

          stream = StringIO.new

          # https://docs.aws.amazon.com/sdkforruby/api/Aws/Glacier/Job.html#get_output-instance_method
          # TODO: do the inverse of what the Chunker class does with SHAs to verify integrity
          _client.get_job_output({
            response_target: stream,
            vault_name: vault_name,
            range: byte_range,
            job_id: job_id,
          })

          Rails.logger.debug "Streaming #{byte_range}"

          cmd_stdin.write(stream.read)
          cmd_stdin.flush

          start_byte = end_byte+1
          end_byte = next_end_byte.call
        end

        cmd_stdin.close
        Rails.logger.info "STDOUT: #{cmd_stdout.read}"
      end
    end
  end
end
