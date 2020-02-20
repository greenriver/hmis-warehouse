class AddPathwaysFlagToHmisAssessments < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_assessments, :vispdat, :boolean, default: false
    add_column :hmis_assessments, :pathways, :boolean, default: false
    add_column :hmis_assessments, :ssm, :boolean, default: false
    add_column :hmis_assessments, :health_case_note, :boolean, default: false
    add_column :hmis_assessments, :health_has_qualifying_activities, :boolean, default: false
    add_column :hmis_assessments, :hud_assessment, :boolean, default: false
    add_column :hmis_assessments, :triage_assessment, :boolean, default: false
    add_column :hmis_assessments, :rrh_assessment, :boolean, default: false
  end
end
