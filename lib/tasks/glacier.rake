namespace :glacier do
  desc "Test"
  task :test, [] => [:environment] do |t, args|
    Rails.logger = Logger.new(STDOUT)
    Glacier::Tester.new.test_all!
  end

  desc "Backup database"
  task :backup, [] => [:environment] do |t, args|
    # You must do these things to set up gpg:
    #   * log in to the server doing the backup
    #   * become ubuntu (sudo su - ubuntu) if you're setting this up for a cronjob
    #   * gpg --gen-key
    #   * set real values for the questions. You don't have to remember the password you use.
    #   * gpg --sign-key openpath.host
    #   * repeat on all servers and for all users you plan to run this task as.
    #   * Note that we do this so that the `gpg -r` part below won't prompt if it's okay to encrypt to an unsigned key. --yes doesn't help.
    #   * accept Todd's apology for having to do this.

    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::INFO
    Glacier::Backup.database!
  end
end
