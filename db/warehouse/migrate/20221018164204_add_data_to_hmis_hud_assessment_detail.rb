class AddDataToHmisHudAssessmentDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_assessment_details, :values, :jsonb
  end
end
