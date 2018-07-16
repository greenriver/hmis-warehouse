class CreateEpicQualifyingActivities < ActiveRecord::Migration
  def change
    create_table :epic_qualifying_activities do |t|
      t.string :patient_id, null: false
      t.string :id_in_source, null: false
      t.string :patient_encounter_id
      t.string :entered_by
      t.string :role
      t.date :date_of_activity
      t.string :activity
      t.string :mode
      t.string :reached
      t.timestamps
      t.integer :data_source_id
    end
  end
end
