class CreateAdHocDataSources < ActiveRecord::Migration[4.2]
  def change
    create_table :ad_hoc_data_sources do |t|
      t.string :name
      t.string :short_name
      t.string :description
      t.boolean :active, null: false, default: true
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :ad_hoc_batches do |t|
      t.references :ad_hoc_data_source
      t.string :description
      t.integer :uploaded_count
      t.integer :matched_count
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
      t.string :import_errors
      t.string :file
      t.string :name
      t.string :size
      t.string :content_type
      t.binary :content
    end

    create_table :ad_hoc_clients do |t|
      t.references :ad_hoc_data_source
      t.references :client
      t.jsonb :matching_client_ids
      t.references :batch
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :ssn
      t.date :dob
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
