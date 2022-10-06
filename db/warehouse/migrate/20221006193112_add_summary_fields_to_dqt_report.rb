class AddSummaryFieldsToDqtReport < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_clients, :veteran_status, :integer
    add_column :hmis_dqt_clients, :ssn, :integer
    add_column :hmis_dqt_clients, :ssn_data_quality, :integer
    add_column :hmis_dqt_clients, :ethnicity, :integer

    add_column :hmis_dqt_enrollments, :project_id, :integer
    add_column :hmis_dqt_enrollments, :household_type, :string
    add_column :hmis_dqt_enrollments, :ch_details_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :los_under_threshold, :integer
    add_column :hmis_dqt_enrollments, :date_to_street_essh, :date
    add_column :hmis_dqt_enrollments, :times_homeless_past_three_years, :integer
    add_column :hmis_dqt_enrollments, :months_homeless_past_three_years, :integer
    add_column :hmis_dqt_enrollments, :enrollment_coc, :string
    add_column :hmis_dqt_enrollments, :has_disability, :boolean, default: false
    add_column :hmis_dqt_enrollments, :days_between_entry_and_create, :integer
    add_column :hmis_dqt_enrollments, :health_dv_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :health_dv_at_entry_collected, :integer

    add_column :hmis_dqt_enrollments, :income_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_at_entry_expected, :boolean, default: false
    add_column :hmis_dqt_enrollments, :earned_income_collected_at_start, :integer
    add_column :hmis_dqt_enrollments, :earned_income_collected_at_annual, :integer
    add_column :hmis_dqt_enrollments, :earned_income_collected_at_exit, :integer
    add_column :hmis_dqt_enrollments, :earned_income_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :earned_amounts_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :ncb_income_collected_at_start, :integer
    add_column :hmis_dqt_enrollments, :ncb_income_collected_at_annual, :integer
    add_column :hmis_dqt_enrollments, :ncb_income_collected_at_exit, :integer
    add_column :hmis_dqt_enrollments, :ncb_income_as_expected_at_entry, :boolean, default: false
    add_column :hmis_dqt_enrollments, :insurance_collected_at_start, :integer
    add_column :hmis_dqt_enrollments, :insurance_collected_at_annual, :integer
    add_column :hmis_dqt_enrollments, :insurance_collected_at_exit, :integer
    add_column :hmis_dqt_enrollments, :insurance_as_expected_at_entry, :boolean, default: false
  end
end
