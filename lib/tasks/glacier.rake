namespace :glacier do
  desc "Test"
  task :test, [] => [:environment] do |t, args|
    Glacier::Tester.new.test_all!
  end

  namespace :backup do
    desc "Backup database"
    task :database, [] => [:environment] do |t, args|
      # You must do these things to set up gpg:
      #   * log in to the server doing the backup
      #   * become ubuntu (sudo su - ubuntu) if you're setting this up for a cronjob
      #   * gpg --gen-key
      #   * set real values for the questions. You don't have to remember the password you use.
      #   * gpg --sign-key openpath.host
      #   * repeat on all servers and for all users you plan to run this task as.
      #   * Note that we do this so that the `gpg -r` part below won't prompt if it's okay to encrypt to an unsigned key. --yes doesn't help.
      #   * accept Todd's apology for having to do this.

      Glacier::Runner.new.database!
    end

    desc "Backup files"
    task :files, [:path] => [:environment] do |t, args|
      args.with_defaults({path: '/var/log'})

      Glacier::Runner.new.files!(args[:path])
    end

    desc "Restore an archive to the filesystem"
    task :restore_file, [:archive_id, :download_path] => [:environment] do |t, args|
      args.with_defaults({download_path: './restored_data'})

      Glacier::Restore.new(archive_id: args[:archive_id], download_path: args[:download_path]).run!
    end

    desc "Stream an archive to a command"
    task :restore_stream, [:archive_id, :processing_cmd] => [:environment] do |t, args|
      args.with_defaults({processing_cmd: 'gpg -d | tar -tz'})

      Glacier::Restore.new(archive_id: args[:archive_id], processing_cmd: args[:processing_cmd]).run!
    end

    desc "Restore archive to database"
    task :restore_database, [:archive_id, :database_name] => [:environment] do |t, args|
      Glacier::Runner.new.restore!(archive_id: args[:archive_id], database_name: args[:database_name])
    end
  end
end
