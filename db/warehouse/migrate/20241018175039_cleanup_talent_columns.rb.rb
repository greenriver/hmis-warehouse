class CleanupTalentColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :talentlms_completed_trainings, :course_id_old, :integer
      remove_column :talentlms_configs, :courseid, :integer
      remove_column :talentlms_configs, :months_to_expiration, :integer
      remove_column :talentlms_configs, :configuration_name, :string
      remove_column :talentlms_configs, :default, :boolean
    end
  end
end