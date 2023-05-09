class AddToRemoteCredentials < ActiveRecord::Migration[6.1]
  def change
    add_column :remote_credentials, :additional_headers, :jsonb, default: {}
    add_column :remote_credentials, :slug, :string, index: true
  end
end
