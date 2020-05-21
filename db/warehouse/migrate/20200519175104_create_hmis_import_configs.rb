class CreateHmisImportConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :hmis_import_configs do |t|
      t.references :data_source, null: false, index: true
      t.boolean :active, default: true
      t.string :s3_access_key_id, null: false
      t.string :encrypted_s3_secret_access_key, null: false
      t.string :encrypted_s3_secret_access_key_iv
      t.string :s3_region
      t.string :s3_bucket_name
      t.string :s3_path
      t.string :encrypted_zip_file_password
      t.string :encrypted_zip_file_password_iv
      t.timestamps
    end
  end
end