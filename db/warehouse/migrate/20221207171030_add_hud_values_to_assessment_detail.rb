class AddHudValuesToAssessmentDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_assessment_details, :hud_values, :jsonb
  end
end
