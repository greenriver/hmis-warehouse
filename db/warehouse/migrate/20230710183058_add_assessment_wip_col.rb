class AddAssessmentWipCol < ActiveRecord::Migration[6.1]
  def change
    Hmis::Hud::CustomAssessment.where(enrollment_id: 'WIP').delete_all
    Hmis::Wip.where(source_type: ['Hmis::Hud::Assessment', 'Hmis::Hud::CustomAssessment']).delete_all

    add_column :CustomAssessments, :wip, :boolean, null: false, default: false
  end
end
