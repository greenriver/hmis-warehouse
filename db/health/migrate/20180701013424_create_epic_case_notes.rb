class CreateEpicCaseNotes < ActiveRecord::Migration
  def change
    create_table :epic_case_notes do |t|
      t.string :patient_id, null: false, index: true
      t.string :id_in_source, null: false
      t.datetime :contact_date
      t.string :closed
      t.string :encounter_type
      t.string :provider_name
      t.string :location
      t.string :chief_complaint_1
      t.string :chief_complaint_1_comment
      t.string :chief_complaint_2
      t.string :chief_complaint_2_comment
      t.string :dx_1_icd10
      t.string :dx_1_name
      t.string :dx_2_icd10
      t.string :dx_2_name
      t.string :homeless_status
      t.integer :data_source_id
      t.timestamps null: false
    end
  end
end
