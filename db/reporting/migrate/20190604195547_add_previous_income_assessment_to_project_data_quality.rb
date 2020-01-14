class AddPreviousIncomeAssessmentToProjectDataQuality < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_data_quality_report_enrollments, :income_at_penultimate_earned, :integer
    add_column :warehouse_data_quality_report_enrollments, :income_at_penultimate_non_employment_cash, :integer
    add_column :warehouse_data_quality_report_enrollments, :income_at_penultimate_overall, :integer
    add_column :warehouse_data_quality_report_enrollments, :income_at_penultimate_response, :integer
  end
end
