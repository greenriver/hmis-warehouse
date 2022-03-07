class CreateHicTables < ActiveRecord::Migration[6.1]
  def change
    HudHic::Generators::Hic::Fy2022::Generator.table_classes.each do |klass|
      klass.hmis_table_create!(version: '2022', constraints: false)
    end

    HudHic::Generators::Hic::Fy2022::Generator.table_classes.each do |klass|
      column_names = klass.column_names
      change_table(klass.table_name) do |t|
        t.integer :report_instance_id,null: false, index: true
        t.integer :data_source_id, null: false, index: true
        t.timestamps
        t.datetime :deleted_at
      end
      add_index klass, [klass.hud_key, :data_source_id, :report_instance_id], unique: true, name: "#{klass.table_name}_uniqueness_constraint"
    end
  end
end
