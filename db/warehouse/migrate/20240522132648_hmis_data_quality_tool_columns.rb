class HmisDataQualityToolColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_dqt_enrollments, :percent_ami, :int4
    add_column :hmis_dqt_enrollments, :vamc_station, :varchar
    add_column :hmis_dqt_enrollments, :veteran, :int4
    add_column :hmis_dqt_enrollments, :hoh_veteran, :int4
    add_column :hmis_dqt_enrollments, :hh_veteran_count, :int4
    add_column :hmis_dqt_enrollments, :target_screen_required, :int4
    add_column :hmis_dqt_enrollments, :target_screen_completed, :boolean
    add_column :hmis_dqt_enrollments, :total_monthly_income_at_entry, :numeric
    add_column :hmis_dqt_enrollments, :total_monthly_income_from_source_at_entry, :numeric
    add_column :hmis_dqt_enrollments, :total_monthly_income_at_exit, :numeric
    add_column :hmis_dqt_enrollments, :total_monthly_income_from_source_at_exit, :numeric

    add_column :hmis_dqt_clients, :afghanistan_oef, :int4
    add_column :hmis_dqt_clients, :iraq_oif, :int4
    add_column :hmis_dqt_clients, :iraq_ond, :int4
    add_column :hmis_dqt_clients, :military_branch, :int4
    add_column :hmis_dqt_clients, :discharge_status, :int4
    add_column :hmis_dqt_clients, :employed, :int4
    add_column :hmis_dqt_clients, :employment_type, :int4
    add_column :hmis_dqt_clients, :not_employed_reason, :int4
  end
end
