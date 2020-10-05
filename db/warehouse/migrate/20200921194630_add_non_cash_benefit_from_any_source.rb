class AddNonCashBenefitFromAnySource < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :non_cash_benefits_from_any_source_at_start, :integer
    add_column :hud_report_apr_clients, :non_cash_benefits_from_any_source_at_annual_assessment, :integer
    add_column :hud_report_apr_clients, :non_cash_benefits_from_any_source_at_exit, :integer
    add_column :hud_report_apr_clients, :insurance_from_any_source_at_start, :integer
    add_column :hud_report_apr_clients, :insurance_from_any_source_at_annual_assessment, :integer
    add_column :hud_report_apr_clients, :insurance_from_any_source_at_exit, :integer
  end
end
