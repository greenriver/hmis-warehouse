###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Wraps the uploader to include inserts into the database and generally manage
# things

require 'open3'

module Glacier
  class Backup
    # The output of this command will be streamed to glacier
    attr_accessor :cmd

    attr_accessor :vault_name, :archive_name
    attr_accessor :vault, :archive
    attr_accessor :uploader
    attr_accessor :notes

    def initialize(cmd:, vault_name:nil, archive_name: nil, notes: nil)
      self.cmd          = cmd
      self.vault_name   = vault_name || default_vault_name
      self.archive_name = archive_name || default_archive_name
      self.notes        = notes
    end

    def run!
      _create_records!
      _stream_to_glacier!
      _save_results!
      # _remove_incomplete_uploads!
    end

    private

    def default_vault_name
      client = ENV.fetch('CLIENT') { 'unknown-client' }

      # Just a heuristic. Set your vault name explicitly if you care
      purpose = self.cmd.match?(/tar/) ? 'logs' : 'backups'

      "#{client}-#{Rails.env}-#{purpose}"
    end

    def default_archive_name
      "archive-#{SecureRandom.hex(8)}"
    end

    def _create_records!
      self.vault = Vault.where(name: vault_name).first_or_initialize
      self.vault.vault_created_at ||= Time.now
      self.vault.last_upload_attempt_at = Time.now
      self.vault.save!

      self.archive = vault.archives.build
    end

    def _stream_to_glacier!
      Rails.logger.info "Streaming #{self.archive_name} to #{self.vault_name}"

      Open3.popen2(cmd) do |stdin, stdout, wait_thread|
        stdin.close

        self.uploader = Uploader.new({
          vault_name: self.vault_name,
          file_stream: stdout,
          archive_name: self.archive_name,
        })

        self.uploader.init!

        self.archive.update({
          upload_id: self.uploader.upload_id,
          upload_started_at: Time.now,
          archive_name: self.archive_name,
          status: "uploading",
          notes: self.notes
        })

        self.uploader.upload!
      end
    end

    def _save_results!
      if self.uploader.successful?
        self.archive.update({
          archive_id: self.uploader.archive_id,
          archive_name: self.archive_name,
          checksum: self.uploader.checksum,
          size_in_bytes: self.uploader.archive_size,
          location: self.uploader.location,
          upload_finished_at: Time.now,
          status: "complete"
        })

        self.vault.update_attribute(:last_upload_success_at, Time.now)
      end
    end

    def _remove_incomplete_uploads!
      Utils.new.cleanup_partial_uploads!(vault_name)
    end
  end
end
