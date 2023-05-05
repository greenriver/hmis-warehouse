class MakeRemoteCredentialSlugsUnique < ActiveRecord::Migration[6.1]
  def change
    add_index :remote_credentials, :slug, unique: true
  end
end
