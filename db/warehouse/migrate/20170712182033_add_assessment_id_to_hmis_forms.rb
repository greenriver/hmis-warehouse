class AddAssessmentIdToHmisForms < ActiveRecord::Migration[4.2]
  def change
    add_reference :hmis_forms, :assessment, index: true
  end
end
