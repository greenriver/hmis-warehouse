class AddIndexToCeAssessments < ActiveRecord::Migration[5.2]
  def change
    remove_index :cas_ce_assessments, :cas_non_hmis_assessment_id
    add_index :cas_ce_assessments, :cas_non_hmis_assessment_id, unique: true
  end
end
