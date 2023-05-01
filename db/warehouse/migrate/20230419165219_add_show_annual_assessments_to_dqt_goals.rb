class AddShowAnnualAssessmentsToDqtGoals < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_goals, :show_annual_assessments, :boolean, default: true
  end
end
