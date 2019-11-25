class AddColumnsToCeAssessments < ActiveRecord::Migration
  def change
    add_column :ce_assessments, :location_no_preference, :boolean
  end
end
