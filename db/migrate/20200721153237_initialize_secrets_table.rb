class InitializeSecretsTable < ActiveRecord::Migration[5.2]
  def up
    if Encryption::Util.encryption_enabled?
      Rake::Task['secrets:init'].execute
    end
  end
end
