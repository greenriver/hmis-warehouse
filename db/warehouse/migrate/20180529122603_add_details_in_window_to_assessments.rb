class AddDetailsInWindowToAssessments < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_assessments, :details_in_window_with_release, :boolean, default: false, null: false
  end
end
