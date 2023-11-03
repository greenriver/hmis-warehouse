class AddHmisActivityLog < ActiveRecord::Migration[6.1]
  def change
    # Should this go in the app db?
    # Index on user id and ds id?

    create_table :hmis_activity_logs do |t|
      t.references :user, null: false, index: true
      t.references :data_source, null: false
      t.string :ip_address, null: false
      t.string :session_hash
      t.string :referer # raw referer
      t.string :path # cleaned/decrypted path
      t.string :operation_name # GraphQL operation name
      t.string :variables # GraphQL variables (JSON)
      t.integer :client_id
      t.integer :enrollment_id
      t.integer :project_id
      t.timestamps
    end
  end
end
