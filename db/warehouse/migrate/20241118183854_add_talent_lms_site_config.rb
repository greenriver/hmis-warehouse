class AddTalentLmsSiteConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :number_lms_courses_required, :integer, default: -1
  end
end
