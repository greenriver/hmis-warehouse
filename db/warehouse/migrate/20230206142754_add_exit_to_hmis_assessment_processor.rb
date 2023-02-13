class AddExitToHmisAssessmentProcessor < ActiveRecord::Migration[6.1]
  def change
    add_reference :hmis_assessment_processors, :exit
  end
end
