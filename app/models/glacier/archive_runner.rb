###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Glacier
  class ArchiveRunner
    include NotifierConfig

    def initialize(host:, databases:, user:, snapshot_date:)
      @db_host = host
      @databases = databases
      @db_user = user
      @snapshot_date = snapshot_date
      setup_notifier("Glacier Backups")
    end

    attr_accessor :databases
    attr_accessor :db_user
    attr_accessor :db_host

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

        databases.each do |database_name|
          Backup.new({
            # cmd: "pg_dump -d #{database_name} --username=#{db_user} --no-password --host=#{db_host} --compress=9 | gpg -e -r #{recipient}",
            cmd: "pg_dump -d #{database_name} --username=#{db_user} --no-password --host=#{db_host} --compress=9",
            archive_name: "#{client}-#{Rails.env}-#{database_name}-no-gpg-#{@snapshot_date}",
            # notes: "Database backup of #{database_name}. Compressed with gzip and encrypted for #{recipient}. Ensure your .pgpass file has the needed password. Restore command will be of the form `gpg -d | gunzip | psql --host= --username= --no-password -d <database>`"
            notes: "Database backup of #{database_name}. Compressed with gzip. Not encrypted. Ensure your .pgpass file has the needed password. Restore command will be of the form `gunzip | psql --host= --username= --no-password -d <database>`"
          }).run!
        end
      end
    end


    private

    define_method(:client)    { ENV.fetch('CLIENT') { 'unknown-client' } }
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
