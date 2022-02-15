###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Glacier
  class Utils < AwsService
    attr_accessor :_client

    def initialize
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
    end

    def operations
      _client.operation_names.ai
    end

    def vaults
      _client.list_vaults.vault_list
    end

    def jobs(vault_name:)
      _client.list_jobs(vault_name: vault_name)
    end

    # This is very slow.
    def list_archives(since: Time.now-QUARTER, vault_name:, job_id: nil)
      if job_id.nil?
        # https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html
        resp = _client.initiate_job({
          account_id: "-",
          job_parameters: {
            description: "Inventory of #{vault_name} since #{since}",
            format: "CSV",
            type: "inventory-retrieval",
            inventory_retrieval_parameters: {
              start_date: since,
              end_date: Time.now
              #limit: "string",
              #marker: "string",
            },
          },
          vault_name: vault_name,
        })

        job_id = resp.job_id
      end

      job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      while(job.status_code == "InProgress")
        Rails.logger.info "sleeping for a moment"
        sleep 1000
        job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      end

      resp = _client.get_job_output({
        response_target: "./inventory.csv",
        account_id: "-",
        vault_name: vault_name,
        job_id: job_id,
      })
    end

    # This is very slow
    def download(vault_name:, archive_id: nil, job_id: nil)
      if job_id.nil?
        # https://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html
        resp = _client.initiate_job({
          account_id: "-",
          job_parameters: {
            description: "Archive retreival from #{vault_name} for #{archive_id}",
            archive_id: archive_id,
            #format: "CSV",
            type: "archive-retrieval",
          },
          vault_name: vault_name,
        })

        job_id = resp.job_id
      end

      job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      while(job.status_code == "InProgress")
        Rails.logger.info "sleeping for a moment"
        sleep 1000
        job = _client.describe_job(job_id: job_id, vault_name: vault_name)
      end

      resp = _client.get_job_output({
        response_target: "./retreived.txt",
        account_id: "-",
        vault_name: vault_name,
        job_id: job_id,
      })
    end

    def partial_uploads(vault_name)
      _client.list_multipart_uploads(account_id: '-', vault_name: vault_name).uploads_list
    end

    def cleanup_partial_uploads!(vault_name)
      partial_uploads(vault_name).each do |upload|
        Rails.logger.info "Removing incomplete #{upload.archive_description} upload from #{vault_name}"
        _client.abort_multipart_upload(upload_id: upload.multipart_upload_id, vault_name: vault_name)
      end
    end

    def delete_archive!(vault_name:, archive_id:)
      _client.delete_archive(vault_name: vault_name, archive_id: archive_id)
    end

    # Must delete all archives first
    def delete_vault!(vault_name)
      _client.delete_vault(vault_name: vault_name)
    end
  end
end
