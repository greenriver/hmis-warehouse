class AddDatesToTalentCourse < ActiveRecord::Migration[7.0]
  def change
    add_column :talentlms_courses, :start_date, :date
    add_column :talentlms_courses, :end_date, :date
  end
end
