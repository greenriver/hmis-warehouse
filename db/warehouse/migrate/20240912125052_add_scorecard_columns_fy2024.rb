class AddScorecardColumnsFy2024 < ActiveRecord::Migration[7.0]
  def change
    add_column :boston_project_scorecard_reports, :materials_concern, :integer
    add_column :boston_project_scorecard_reports, :lms_completed, :boolean
    add_column :boston_project_scorecard_reports, :self_certified, :boolean
    add_column :boston_project_scorecard_reports, :days_to_lease_up_comparison, :integer
  end
end
