class AddCeAssessmentToFormProcessor < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_reference :hmis_form_processors, :ce_assessment
    end
  end
end
