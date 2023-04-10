class ClientMciId < ActiveRecord::Migration[6.1]
  def change
    create_table :external_request_logs do |t|
      t.references :initiator, polymorphic: true

      t.string :identifier
      # t.jsonb :credentials #(user, token)

      t.string :content_type
      t.string :url, null: false
      t.string :http_method, null: false, default: 'GET'
      t.inet :ip
      t.jsonb :request_headers, default: {}, null: false
      t.text :request, null: false
      t.text :response, null: false
      t.datetime :requested_at, null: false
      t.timestamps

      t.index :requested_at
      t.index :ip
      t.index [:initiator_id, :initiator_type]
    end

    create_table :external_ids do |t|
      t.string :value, null: false
      t.references :source, polymorphic: true, null: false # (Client, Project, Organization, etc.)
      t.references :remote_credential, foreign_key: true  # (MCI, MPER, etc.)
      t.references :external_request_log, foreign_key: true
      t.timestamps

      t.index :value
      t.index [:source_id, :source_type, :value], unique: true
    end
  end
end
