class CreateEpicCaseNoteQualifyingActivities < ActiveRecord::Migration
  def change
    create_table :epic_case_note_qualifying_activities do |t|
      t.string :patient_id
      t.string :id_in_source
      t.string :epic_case_note_source_id
      t.string :encounter_type
      t.datetime :update_date
      t.string :staff
      t.text :part_1
      t.text :part_2
      t.text :part_3
      t.timestamps
      t.integer :data_source_id
    end
  end
end