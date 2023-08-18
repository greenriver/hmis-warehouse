class HmisUnitAvailabilitySyncTracking < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_project_unit_type_mappings, :last_synced_values, :jsonb
    add_column :hmis_project_unit_type_mappings, :last_synced_at, :datetime
  end
end
