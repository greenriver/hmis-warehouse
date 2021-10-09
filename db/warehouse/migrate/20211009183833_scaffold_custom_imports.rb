class ScaffoldCustomImports < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_imports_config do |t|
      t.references :user
      t.references :data_source
      t.boolean :active, default: true, null: false
      t.string :description
      t.integer :import_hour
      t.string :import_type
      t.string :recurring_hmis_exports, :s3_region
      t.string :recurring_hmis_exports, :s3_bucket
      t.string :recurring_hmis_exports, :s3_prefix
      t.string :recurring_hmis_exports, :encrypted_s3_access_key_id
      t.string :recurring_hmis_exports, :encrypted_s3_access_key_id_iv
      t.string :recurring_hmis_exports, :encrypted_s3_secret
      t.string :recurring_hmis_exports, :encrypted_s3_secret_iv
      t.datetime :last_import_attempted_at
      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end

    create_table :custom_imports_files do |t|
      t.string :type
      t.references :config
      t.references :user
      t.references :data_source
      t.references :delayed_job
      t.string :file
      t.float :percent_complete
      t.jsonb :summary
      t.jsonb :import_errors
      t.string :content_type
      t.binary :content

      t.timestamps null: false, index: true
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at
    end

    create_table :custom_imports_boston_rows do |t|
      t.references :file
      t.integer :row_number, null: false
      t.string :personal_id, null: false
      t.string :agency_id, null: false
      t.string :enrollment_id
      t.string :service_id
      t.date :date
      t.string :service_name
      t.string :service_category
      t.string :service_program_name
      t.timestamps null: false, index: true
    end
  end
end
