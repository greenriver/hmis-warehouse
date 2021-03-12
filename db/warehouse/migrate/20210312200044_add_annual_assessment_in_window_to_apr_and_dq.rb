class AddAnnualAssessmentInWindowToAprAndDq < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :annual_assessment_in_window, :boolean
    add_column :hud_report_dq_clients, :annual_assessment_in_window, :boolean
  end
end
