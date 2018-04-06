class CreateEpicGoals < ActiveRecord::Migration
  def change
    create_table :epic_goals do |t|
      t.string :patient_id, null: false, index: true
      t.string :entered_by
      t.string :title
      t.string :contents
      t.string :id_in_source
      t.string :received_valid_complaint
      t.datetime :goal_created_at
      t.timestamps null: false
    end
  end
end
