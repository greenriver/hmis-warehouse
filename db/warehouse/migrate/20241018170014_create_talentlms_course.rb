class CreateTalentlmsCourse < ActiveRecord::Migration[7.0]
  def change
    create_table :talentlms_courses do |t|
      t.references :config, foreign_key: { to_table: :talentlms_configs }
      t.integer :courseid
      t.integer :months_to_expiration
      t.string :name
      t.boolean :default, default: false
    end
    safety_assured do
      add_reference :talentlms_logins, :config, foreign_key: { to_table: :talentlms_configs }
      rename_column :talentlms_completed_trainings, :course_id, :course_id_old
      add_reference :talentlms_completed_trainings, :course, foreign_key: { to_table: :talentlms_courses }
    end
  end
end
