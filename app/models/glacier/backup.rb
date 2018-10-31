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

    def initialize(cmd:, vault_name:nil, archive_name: nil)
      self.cmd          = cmd
      self.vault_name   = vault_name || default_vault_name
      self.archive_name = archive_name || default_archive_name
    end

    DB_CONFIG = Rails.configuration.database_configuration[Rails.env]
    define_singleton_method(:db_user) { DB_CONFIG['username'] }
    define_singleton_method(:db_host) { DB_CONFIG['host'] || 'localhost' }
    define_singleton_method(:recipient) { ENV['ENCRYPTION_RECIPIENT'] }

    def self.database!
      # You must do these things to set up gpg:
      #   * log in to the server doing the backup
      #   * become ubuntu (sudo su - ubuntu) if you're setting this up for a cronjob
      #   * gpg --gen-key
      #   * set real values for the questions. You don't have to remember the password you use.
      #   * gpg --sign-key openpath.host
      #   * repeat on all servers and for all users you plan to run this task as.
      #   * Note that we do this so that the `gpg -r` part below won't prompt if it's okay to encrypt to an unsigned key. --yes doesn't help.
      #   * accept Todd's apology for having to do this.

      databases = if ENV['GLACIER_DATABASES'].blank? || ENV['GLACIER_DATABASES'] == 'DEFAULT'
                    [
                      DB_CONFIG['database'],
                      ENV['WAREHOUSE_DATABASE_DB'],
                      ENV['DATABASE_CAS_DB']
                    ]
                  else
                    ENV['GLACIER_DATABASES'].split(",")
                  end

      client = ENV.fetch('CLIENT') { 'unknown-client' }

      databases.each do |database_name|
        new({
          cmd: "pg_dump -d #{database_name} --username=#{db_user} --no-password --host=#{db_host} --compress=9 | gpg -e -r #{recipient}",
          archive_name: "#{client}-#{Rails.env}-#{database_name}-#{Time.now.to_s(:iso8601)}"
        }).run!
      end

    end

    # WIP:
    #def self.logs!
    #  new(cmd: "tar -c /var/logs | gpg -e -r #{recipient}").run!
    #end

    def default_vault_name
      client = ENV.fetch('CLIENT') { 'unknown-client' }

      # Just a heuristic. Set your vault name explicitly if you care
      purpose = self.cmd.match?(/tar/) ? 'logs' : 'backups'

      "#{client}-#{Rails.env}-#{purpose}"
    end

    def default_archive_name
      "archive-#{SecureRandom.hex(8)}"
    end

    def run!
      _create_records!
      _stream_to_glacier!
      _save_results!
      _remove_incomplete_uploads!
    end

    private

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

        self.archive.update_attributes({
          upload_id: self.uploader.upload_id,
          upload_started_at: Time.now,
          status: "uploading"
        })

        self.uploader.upload!
      end
    end

    def _save_results!
      if self.uploader.successful?
        self.archive.update_attributes({
          archive_id: self.uploader.archive_id,
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
