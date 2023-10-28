class HmisUnitAvailabilitySyncTracking < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_external_unit_availability_syncs do |t|
      t.references :project, null: false, foreign_key: { to_table: 'Project' }, index: false
      t.references :unit_type, null: false, foreign_key: { to_table: 'hmis_unit_types' }
      t.references :user, null: false
      t.integer :local_version, null: false, default: 0
      t.integer :synced_version, null: false, default: 0
      t.index [:project_id, :unit_type_id], unique: true, name: 'uidx_hmis_external_unit_availability_syncs'
    end
  end
end
