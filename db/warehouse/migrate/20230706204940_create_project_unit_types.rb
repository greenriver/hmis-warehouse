class CreateProjectUnitTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_project_unit_type_mappings do |t|
      t.references :project, null: false, foreign_key: { to_table: 'Project'}
      t.references :unit_type, null: false, index: true, foreign_key: { to_table: 'hmis_unit_types'}
      t.integer :unit_capacity
      t.boolean :active, null: false
      t.timestamps
      t.index [:project_id, :unit_type_id], unique: true, name: 'uidx_hmis_project_unit_type_mappings'
    end
  end
end
