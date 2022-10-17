class AddSummaryFieldsToDqtReport < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_clients, :veteran_status, :integer
    add_column :hmis_dqt_clients, :ssn, :string
    add_column :hmis_dqt_clients, :ssn_data_quality, :integer
    add_column :hmis_dqt_clients, :name_data_quality, :integer
    add_column :hmis_dqt_clients, :ethnicity, :integer
    add_column :hmis_dqt_clients, :reporting_age, :integer

    add_column :hmis_dqt_enrollments, :project_id, :integer
    add_column :hmis_dqt_enrollments, :household_type, :string
    add_column :hmis_dqt_enrollments, :household_min_age, :integer
    add_column :hmis_dqt_enrollments, :ch_details_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :los_under_threshold, :integer
    add_column :hmis_dqt_enrollments, :date_to_street_essh, :date
    add_column :hmis_dqt_enrollments, :times_homeless_past_three_years, :integer
    add_column :hmis_dqt_enrollments, :months_homeless_past_three_years, :integer
    add_column :hmis_dqt_enrollments, :enrollment_coc, :string
    add_column :hmis_dqt_enrollments, :has_disability, :boolean, default: false
    add_column :hmis_dqt_enrollments, :days_between_entry_and_create, :integer
    add_column :hmis_dqt_enrollments, :health_dv_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :domestic_violence_victim_at_entry, :integer

    add_column :hmis_dqt_enrollments, :income_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :income_at_annual_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :income_at_exit_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_at_annual_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_at_exit_expected, :boolean, default: false

    add_column :hmis_dqt_enrollments, :income_from_any_source_at_entry, :integer
    add_column :hmis_dqt_enrollments, :income_from_any_source_at_annual, :integer
    add_column :hmis_dqt_enrollments, :income_from_any_source_at_exit, :integer

    add_column :hmis_dqt_enrollments, :cash_income_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :cash_income_as_expected_at_annual, :boolean, default: false
    add_column :hmis_dqt_enrollments, :cash_income_as_expected_at_exit, :boolean, default: false

    add_column :hmis_dqt_enrollments, :ncb_from_any_source_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ncb_from_any_source_at_annual, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ncb_from_any_source_at_exit, :boolean, default: false

    add_column :hmis_dqt_enrollments, :ncb_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ncb_as_expected_at_annual, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ncb_as_expected_at_exit, :boolean, default: false

    add_column :hmis_dqt_enrollments, :insurance_from_any_source_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_from_any_source_at_annual, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_from_any_source_at_exit, :boolean, default: false

    add_column :hmis_dqt_enrollments, :insurance_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_as_expected_at_annual, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_as_expected_at_exit, :boolean, default: false

    add_column :hmis_dqt_enrollments, :disability_at_entry_collected, :boolean, default: false
  end
end
