class ConfigurableClientRecordPage < ActiveRecord::Migration[7.0]
  def change
    create_table(:hmis_supplemental_data_sets) do |t|
      t.timestamps
      t.references :data_source, null: false
      t.references :remote_credential
      t.string :owner_type, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.jsonb :field_configs, null: false
      t.index [:slug], unique: true
    end

    create_table(:hmis_supplemental_field_values) do |t|
      t.references :data_set, null: false, index: false
      t.references :data_source, null: false
      t.string :field_key, null: false
      t.string :owner_key, null: false
      t.jsonb :data, null: false
      t.index [:data_set_id, :owner_key, :field_key], unique: true, name: 'uidx_hmis_supplemental_field_values_on_key'
    end
  end
end
