class AddUniqueConstraintToRemoteCredential < ActiveRecord::Migration[6.1]
  def change
    add_index :remote_credentials, :type, unique: true
  end
end
