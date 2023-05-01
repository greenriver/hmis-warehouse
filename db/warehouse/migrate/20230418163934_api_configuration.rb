class ApiConfiguration < ActiveRecord::Migration[6.1]
  def change
    create_table :inbound_api_configurations do |t|
      t.string :internal_system_name, null: false  # (e.g. referral, involvement)
      t.string :external_system_name, null: false  # (e.g. LINK, MPER)
      t.string :hashed_api_key, null: false
      t.string :plain_text_reminder, null: false
      t.integer :version, null: false, default: 0

      t.timestamps
    end

    add_index :inbound_api_configurations, :hashed_api_key, unique: true
    add_index :inbound_api_configurations, :plain_text_reminder
    add_index :inbound_api_configurations, [:internal_system_name, :external_system_name, :version], unique: true, name: "idx_api_conf_on_name_and_external_name"
  end
end
