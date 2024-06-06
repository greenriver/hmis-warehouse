class CreateAppSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :app_config_properties do |t|
      t.string :key, null: false
      t.jsonb :value, null: false

      t.timestamps
    end
    add_index :app_config_properties, :key, unique: true
  end
end
