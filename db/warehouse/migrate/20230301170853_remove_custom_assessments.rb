class RemoveCustomAssessments < ActiveRecord::Migration[6.1]
  def up
    # Remove any custom assessments from the HUD CE Assessments table
    Hmis::Hud::Assessment.where(AssessmentType: 999).destroy_all
    Hmis::Wip.where(source_type: 'Hmis::Hud::Assessment').destroy_all
  end
end
