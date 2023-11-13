class AddHmisActivityLog < ActiveRecord::Migration[6.1]
  def change
    # Should this go in the app db?
    # Index on user id and ds id?

    create_table :hmis_activity_logs do |t|
      t.references :user, null: false, index: true
      t.references :data_source, null: false
      t.jsonb :resolved_fields
      t.string :ip_address, null: false
      t.string :session_hash
      t.jsonb :variables, comment: 'GraphQL variables'
      t.string :referer, comment: 'user-provided'
      t.string :operation_name, comment: 'user-provided GraphQL operation name'
      t.string :header_page_path, comment: 'user-provided, decrypted path'
      t.references :header_client, comment: 'user-provided'
      t.references :header_enrollment, comment: 'user-provided'
      t.references :header_project, comment: 'user-provided'
      t.timestamp :created_at, null: false
    end
  end
end
