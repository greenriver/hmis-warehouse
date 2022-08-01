class CreateCeSupplemental < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :supplemental_enrollment_importer, :string, default: 'GrdaWarehouse::Tasks::EnrollmentExtrasImport'
    change_table :ce_performance_ce_aprs do |t|
      t.boolean :cls_literally_homeless, default: false, null: false
      t.string :vispdat_type
      t.string :vispdat_range
      t.string :prioritization_tool_type
      t.integer :prioritization_tool_score
      t.string :community
      t.boolean :lgbtq_household_members, default: false, null: false
      t.boolean :client_lgbtq, default: false, null: false
      t.boolean :dv_survivor, default: false, null: false
      t.integer :prevention_tool_score
    end
    change_table :enrollment_extras do |t|
      t.references :file, index: true
      t.integer :data_source_id
      t.string :client_id
      t.string :client_uid
      t.string :hud_enrollment_id
      t.string :enrollment_group_id
      t.string :project_name
      t.date :entry_date
      t.date :exit_date
      t.string :vispdat_type
      t.string :vispdat_range
      t.string :prioritization_tool_type
      t.integer :prioritization_tool_score
      t.string :agency_name
      t.string :community
      t.boolean :lgbtq_household_members
      t.boolean :client_lgbtq
      t.boolean :dv_survivor
      t.integer :prevention_tool_score
    end

    add_index :enrollment_extras, [:client_id, :data_source_id]
    add_index :enrollment_extras, [:hud_enrollment_id, :data_source_id]
    add_index(
      :enrollment_extras,
      [
        :hud_enrollment_id,
        :entry_date,
        :vispdat_ended_at,
        :project_name,
        :agency_name,
        :community,
        :data_source_id,
      ],
      unique: true,
      name: :idx_tpc_uniqueness,
    )
    change_column_null :enrollment_extras, :enrollment_id, true, nil
  end
end
