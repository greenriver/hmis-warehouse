class ClaimsReportingMemberEnrollmentRosters < ActiveRecord::Migration[5.2]
  def change
    create_table "claims_reporting_member_enrollment_rosters" do |t|
      t.column 'member_id', 'string', limit: 50
      t.column 'performance_year', 'string', limit: 50
      t.column 'region', 'string', limit: 50
      t.column 'service_area', 'string', limit: 50
      t.column 'aco_pidsl', 'string', limit: 50
      t.column 'aco_name', 'string', limit: 255
      t.column 'pcc_pidsl', 'string', limit: 50
      t.column 'pcc_name', 'string', limit: 255
      t.column 'pcc_npi', 'string', limit: 50
      t.column 'pcc_taxid', 'string', limit: 50
      t.column 'mco_pidsl', 'string', limit: 50
      t.column 'mco_name', 'string', limit: 50
      t.column 'enrolled_flag', 'string', limit: 50
      t.column 'enroll_type', 'string', limit: 50
      t.column 'enroll_stop_reason', 'string', limit: 50
      t.column 'rating_category_char_cd', 'string', limit: 255
      t.column 'ind_dds', 'string', limit: 50
      t.column 'ind_dmh', 'string', limit: 50
      t.column 'ind_dta', 'string', limit: 50
      t.column 'ind_dss', 'string', limit: 50
      t.column 'cde_hcb_waiver', 'string', limit: 50
      t.column 'cde_waiver_category', 'string', limit: 50
      t.column 'span_start_date', 'date', limit: nil
      t.column 'span_end_date', 'date', limit: nil
      t.column 'span_mem_days', 'int', limit: nil
      t.column 'cp_prov_type', 'string', limit: 255
      t.column 'cp_plan_type', 'string', limit: 255
      t.column 'cp_pidsl', 'string', limit: 50
      t.column 'cp_prov_name', 'string', limit: 512
      t.column 'cp_enroll_dt', 'date', limit: nil
      t.column 'cp_disenroll_dt', 'date', limit: nil
      t.column 'cp_start_rsn', 'string', limit: 255
      t.column 'cp_stop_rsn', 'string', limit: 255
      t.column 'ind_medicare_a', 'string', limit: 50
      t.column 'ind_medicare_b', 'string', limit: 50
      t.column 'tpl_coverage_cat', 'string', limit: 50
      t.timestamps null: true
    end
  end
end
