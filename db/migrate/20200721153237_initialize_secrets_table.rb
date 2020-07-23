class InitializeSecretsTable < ActiveRecord::Migration[5.2]
  def up
    if Encryption::Util.encryption_enabled?
      Rake::Task['secrets:init'].execute
      Rake::Task['secrets:copy_cleartext'].execute
      Rake::Task['secrets:wipe'].execute
    end
  end
end
