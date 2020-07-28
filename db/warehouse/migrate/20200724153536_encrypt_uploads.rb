class EncryptUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :uploads, :encrypted_content, :text
    add_column :uploads, :encrypted_content_iv, :string
    add_column :import_logs, :encrypted_import_errors, :text
    add_column :import_logs, :encrypted_import_errors_iv, :string
  end
end
