###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health::CpMembers
  class EnrollmentRosterFile < FileBase
    has_many :enrollment_rosters, class_name: 'Health::CpMembers::EnrollmentRoster', inverse_of: :enrollment_roster_file

    private def model
      Health::CpMembers::EnrollmentRoster
    end

    private def expected_header
      'member_id,performance_year,region,service_area,aco_pidsl,aco_name,pcc_pidsl,pcc_name,pcc_npi,pcc_taxid,mco_pidsl,mco_name,enrolled_flag,enroll_type,enroll_stop_reason,rating_category_char_cd,ind_dds,ind_dmh,ind_dta,ind_dss,cde_hcb_waiver,cde_waiver_category,span_start_date,span_end_date,span_mem_days,cp_prov_type,cp_plan_type,cp_pidsl,cp_prov_name,cp_enroll_dt,cp_disenroll_dt,cp_start_rsn,cp_stop_rsn,ind_medicare_a,ind_medicare_b,tpl_coverage_cat'
    end
  end
end