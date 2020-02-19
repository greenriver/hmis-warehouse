class AddCourseidToTalentLmsConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :talentlms_configs, :courseid, :integer
  end
end
