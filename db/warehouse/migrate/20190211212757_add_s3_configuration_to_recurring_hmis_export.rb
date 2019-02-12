class AddS3ConfigurationToRecurringHmisExport < ActiveRecord::Migration
  def change
    add_column :recurring_hmis_exports, :s3_region, :string
    add_column :recurring_hmis_exports, :s3_bucket, :string
    add_column :recurring_hmis_exports, :encrypted_s3_access_key_id, :string
    add_column :recurring_hmis_exports, :encrypted_s3_access_key_id_iv, :string
    add_column :recurring_hmis_exports, :encrypted_s3_secret, :string
    add_column :recurring_hmis_exports, :encrypted_s3_secret_iv, :string

    add_index :recurring_hmis_exports, :encrypted_s3_access_key_id_iv, unique: true
    add_index :recurring_hmis_exports, :encrypted_s3_secret_iv, unique: true
  end
end
