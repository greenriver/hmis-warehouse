class CreateHmisTableConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_table_configurations do |t|
      t.string :table_key, null: false # Unique key for the table configuration
      t.references :owner, polymorphic: true, index: true # Optional owner of the config. Empty for globally configured tables.
      t.bigint :data_source_id, null: false # HMIS Data Source that configuration belongs to
      t.jsonb :display_columns, null: false, default: [] # JSONB for column configurations
      t.jsonb :filter_configurations, null: false, default: [] # JSONB for filter configurations

      t.timestamps
    end

    add_index :hmis_table_configurations, [:table_key, :owner_type, :owner_id], unique: true, name: 'index_hmis_table_configurations_on_key_and_owner'
  end
end
