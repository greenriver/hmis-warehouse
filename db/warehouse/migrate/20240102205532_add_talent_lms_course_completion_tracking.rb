class AddTalentLmsCourseCompletionTracking < ActiveRecord::Migration[6.1]
  def change
      create_table :talentlms_completed_trainings do |t|
        t.references :login, null: false
        t.references :config, null: false
        t.integer :course_id, null: false
        t.date :completion_date, null: false
      end
  end
end
