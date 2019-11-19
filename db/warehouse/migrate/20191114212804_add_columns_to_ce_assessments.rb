class AddColumnsToCeAssessments < ActiveRecord::Migration[4.2]
  def change
    add_column :ce_assessments, :location_no_preference, :boolean
  end
end
