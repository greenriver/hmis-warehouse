class RecreateHmisClientAlerts < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_client_alerts do |t|
      t.text :note, null: false
      t.timestamps
      t.timestamp :deleted_at
      t.date :expiration_date
      t.references :created_by, null: false, index: true
      t.references :client, null: false, index: true
      t.string :severity
    end
  end
end
