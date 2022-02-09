###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health::CpMembers
  class EnrollmentRosterFile < FileBase
    has_many :rosters, class_name: 'Health::CpMembers::EnrollmentRoster', foreign_key: :roster_file_id, inverse_of: :roster_file

    def label
      'CP Member Enrollment Roster'
    end

    def columns
      {
        member_id: 'Member ID',
        performance_year: 'Performance Year',
        region: 'Region',
        service_area: 'Service Area',
        aco_pidsl: 'ACO PID/SL',
        aco_name: 'ACO Name',
        pcc_pidsl: 'PCC PID/SL',
        pcc_name: 'PCC Name',
        pcc_npi: 'PCC NPI',
        pcc_taxid: 'PCC Tax ID',
        mco_pidsl: 'MCO PID/SL',
        mco_name: 'MCO Name',
        enrolled_flag: 'Enrolled?',
        enroll_type: 'Enrollment Type',
        enroll_stop_reason: 'Enrollment Stop Reason',
        rating_category_char_cd: 'Rating Category',
        ind_dds: 'DSS?',
        ind_dmh: 'DMH?',
        ind_dta: 'DTA?',
        ind_dss: 'DCF?',
        cde_hcb_waiver: 'HCB Waiver Code',
        cde_waiver_category: 'HCB Waiver Category',
        span_start_date: 'Span Start Date',
        span_end_date: 'Span End Date',
        span_mem_days: 'Span Member Days',
        cp_prov_type: 'CP Provider Type',
        cp_plan_type: 'CP Plan Type',
        cp_pidsl: 'CP PID/SL',
        cp_prov_name: 'CP Provider Name',
        cp_enroll_dt: 'CP Enrollment Date',
        cp_disenroll_dt: 'CP Disenrollment Date',
        cp_start_rsn: 'CP Start Reason',
        cp_stop_rsn: 'CP Stop Reason',
        ind_medicare_a: 'Medicare Part A?',
        ind_medicare_b: 'Medicare Part B?',
        tpl_coverage_cat: 'TPL Coverage Category',
      }
    end

    private def model
      Health::CpMembers::EnrollmentRoster
    end

    private def expected_header
      'member_id,performance_year,region,service_area,aco_pidsl,aco_name,pcc_pidsl,pcc_name,pcc_npi,pcc_taxid,mco_pidsl,mco_name,enrolled_flag,enroll_type,enroll_stop_reason,rating_category_char_cd,ind_dds,ind_dmh,ind_dta,ind_dss,cde_hcb_waiver,cde_waiver_category,span_start_date,span_end_date,span_mem_days,cp_prov_type,cp_plan_type,cp_pidsl,cp_prov_name,cp_enroll_dt,cp_disenroll_dt,cp_start_rsn,cp_stop_rsn,ind_medicare_a,ind_medicare_b,tpl_coverage_cat'
    end
  end
end
