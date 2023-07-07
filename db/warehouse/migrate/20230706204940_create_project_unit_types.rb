class CreateProjectUnitTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_project_unit_types do |t|
      t.bigint 'ProgramID', null: false
      t.bigint 'UnitTypeID', null: false, index: true
      t.references :data_source, null: false
      t.integer 'UnitCapacity'
      t.string 'isActive'
      t.timestamps
      t.index ['ProgramID', 'UnitTypeID', :data_source_id], unique: true, name: 'uidx_hmis_project_unit_type'
    end
  end
end
