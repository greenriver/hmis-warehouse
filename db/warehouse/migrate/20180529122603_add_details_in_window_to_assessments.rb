class AddDetailsInWindowToAssessments < ActiveRecord::Migration
  def change
    add_column :hmis_assessments, :details_in_window_with_release, :boolean, default: false, null: false
  end
end
