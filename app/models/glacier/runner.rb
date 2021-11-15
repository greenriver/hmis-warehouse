###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Glacier
  class Runner
    include NotifierConfig

    DB_CONFIG = Rails.configuration.database_configuration[Rails.env]

    def initialize
      setup_notifier("Glacier Backups")
    end

    def restore_database!(archive_id:, database_name:, provided_db_host: nil)
      different_host = provided_db_host.present? && provided_db_host != db_host
      safe_db_name = database_name.match?(/restore/i)

      if !(different_host || safe_db_name)
        raise "Database name must have restore in it for safety or you must be restoring to a new host. Remove this line if you know what you're doing."
      end

      host_to_use = provided_db_host || db_host

      if ENV['ADDED_EXTENSIONS'].present?
        # processing_cmd = "gpg -d | gunzip | psql -d #{database_name} --username=#{db_user} --no-password --host=#{host_to_use}"
        processing_cmd = "gunzip | psql -d #{database_name} --username=#{db_user} --no-password --host=#{host_to_use}"

        Restore.new({
          archive_id: archive_id,
          processing_cmd: processing_cmd
        }).run!
      else
        Rails.logger.info "Creating #{database_name} if it doesn't exist"
        system("psql -d postgres --username=#{db_user} --no-password --host=#{host_to_use} -c 'create database #{database_name}'")

        puts(<<~EOS)
          Connect to #{database_name} as the RDS superuser and run these commands:

          CREATE EXTENSION hstore;
          CREATE EXTENSION fuzzystrmatch;
          CREATE EXTENSION pg_stat_statements;

          When complete, rerun this rake task prefixed with ADDED_EXTENSIONS=true
        EOS
      end
    end

    def database!
      _safely do
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
                      dbs = [
                        ENV['DATABASE_APP_DB'],
                        ENV['WAREHOUSE_DATABASE_DB'],
                      ]
                      dbs << ENV['DATABASE_CAS_DB'] if CasBase.db_exists?
                      dbs
                    else
                      ENV['GLACIER_DATABASES'].split(",")
                    end

        databases.each do |database_name|
          Backup.new({
            # cmd: "pg_dump -d #{database_name} --username=#{db_user} --no-password --host=#{db_host} --compress=9 | gpg -e -r #{recipient}",
            cmd: "pg_dump -d #{database_name} --username=#{db_user} --no-password --host=#{db_host} --compress=9",
            archive_name: "#{client}-#{Rails.env}-#{database_name}-no-gpg-#{Time.now.to_s(:iso8601)}",
            # notes: "Database backup of #{database_name}. Compressed with gzip and encrypted for #{recipient}. Ensure your .pgpass file has the needed password. Restore command will be of the form `gpg -d | gunzip | psql --host= --username= --no-password -d <database>`"
            notes: "Database backup of #{database_name}. Compressed with gzip. Not encrypted. Ensure your .pgpass file has the needed password. Restore command will be of the form `gunzip | psql --host= --username= --no-password -d <database>`"
          }).run!
        end
      end
    end

    def files!(path)
      _safely do
        # cmd = "sudo tar -zcf - #{path} | gpg -e -r #{recipient}"
        cmd = "sudo tar -zcf - #{path}"
        norm_path = path.gsub(/[^\d\w]/, '_')

        Backup.new({
          cmd: cmd,
          archive_name: "#{client}-#{Rails.env}-#{norm_path}-#{Time.now.to_s(:iso8601)}",
          # notes: "File system backup. Path: [#{path}]. Compressed with gzip and encrypted for #{recipient}. Restore command will be of the form `gpg -d | tar -zxf - -C ./place_to_restore",
          notes: "File system backup. Path: [#{path}]. Compressed with gzip and encrypted for #{recipient}. Restore command will be of the form `tar -zxf - -C ./place_to_restore",
        }).run!
      end
    end

    private

    define_method(:client)    { ENV.fetch('CLIENT') { 'unknown-client' } }
    define_method(:db_host)   { DB_CONFIG['host'] || 'localhost' }
    define_method(:db_user)   { DB_CONFIG['username'] }
    define_method(:recipient) { ENV.fetch('ENCRYPTION_RECIPIENT') }

    def _safely
      begin
        yield
      rescue StandardError => e
        @notifier.ping("Glacier backups failed\n#{e.message}\n #{e.backtrace.join("\n")}") if @send_notifications
        raise e
      end
    end
  end
end
