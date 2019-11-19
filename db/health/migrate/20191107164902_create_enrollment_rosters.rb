class CreateEnrollmentRosters < ActiveRecord::Migration[4.2]
  def change
    create_table :enrollment_rosters do |t|
      t.belongs_to :roster_file

      t.string :member_id
      t.string :performance_year
      t.string :region
      t.string :service_area
      t.string :aco_pidsl
      t.string :aco_name
      t.string :pcc_pidsl
      t.string :pcc_name
      t.string :pcc_npi
      t.string :pcc_taxid
      t.string :mco_pidsl
      t.string :mco_name
      t.string :enrolled_flag
      t.string :enroll_type
      t.string :enroll_stop_reason
      t.string :rating_category_char_cd
      t.string :ind_dds
      t.string :ind_dmh
      t.string :ind_dta
      t.string :ind_dss
      t.string :cde_hcb_waiver
      t.string :cde_waiver_category
      t.date :span_start_date
      t.date :span_end_date
      t.integer :span_mem_days
      t.string :cp_prov_type
      t.string :cp_plan_type
      t.string :cp_pidsl
      t.string :cp_prov_name
      t.date :cp_enroll_dt
      t.date :cp_disenroll_dt
      t.string :cp_start_rsn
      t.string :cp_stop_rsn
      t.string :ind_medicare_a
      t.string :ind_medicare_b
      t.string :tpl_coverage_cat
    end
  end
end
