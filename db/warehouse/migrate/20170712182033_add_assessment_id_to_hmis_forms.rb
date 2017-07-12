class AddAssessmentIdToHmisForms < ActiveRecord::Migration
  def change
    add_reference :hmis_forms, :assessment, index: true
  end
end
