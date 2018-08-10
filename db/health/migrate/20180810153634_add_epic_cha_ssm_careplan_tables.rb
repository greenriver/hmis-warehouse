class AddEpicChaSsmCareplanTables < ActiveRecord::Migration
  def change
    create_table :epic_careplans do |t|
      t.string :patient_id
      t.string :id_in_source
      t.string :encounter_id
      t.string :encounter_type
      t.datetime :careplan_updated_at
      t.string :staff
      t.text :part_1
      t.text :part_2
      t.text :part_3
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :data_source_id
    end
    create_table :epic_ssms do |t|
      t.string :patient_id
      t.string :id_in_source
      t.string :encounter_id
      t.string :encounter_type
      t.datetime :ssm_updated_at
      t.string :staff
      t.text :part_1
      t.text :part_2
      t.text :part_3
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :data_source_id
    end
    create_table :epic_chas do |t|
      t.string :patient_id
      t.string :id_in_source
      t.string :encounter_id
      t.string :encounter_type
      t.datetime :cha_updated_at
      t.string :staff
      t.string :provider_type
      t.string :reviewer_name
      t.string :reviewer_provider_type
      t.text :part_1
      t.text :part_2
      t.text :part_3
      t.text :part_4
      t.text :part_5
      t.text :part_6
      t.text :part_7
      t.text :part_8
      t.text :part_9
      t.text :part_10
      t.text :part_11
      t.text :part_12
      t.text :part_13
      t.text :part_14
      t.text :part_15
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :data_source_id
    end
  end
end
