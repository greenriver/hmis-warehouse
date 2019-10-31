class AddHealthColumnToHmisAssessments < ActiveRecord::Migration[4.2]
  def up
    add_column :hmis_assessments, :health, :boolean, default: false, null: false
  end
  def down
    remove_column :hmis_assessments, :health, :boolean
  end
end
