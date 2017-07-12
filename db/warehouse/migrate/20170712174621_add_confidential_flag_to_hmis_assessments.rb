class AddConfidentialFlagToHmisAssessments < ActiveRecord::Migration
  def change
    add_column :hmis_assessments, :confidential, :boolean, default: false, null: false
    add_column :hmis_assessments, :exclude_from_window, :boolean, default: false, null: false
  end
end
