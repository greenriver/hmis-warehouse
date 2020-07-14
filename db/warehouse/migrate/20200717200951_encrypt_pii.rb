class EncryptPII < ActiveRecord::Migration[5.2]
  def up
    Rake::Task['secrets:init'].execute
  end
end
