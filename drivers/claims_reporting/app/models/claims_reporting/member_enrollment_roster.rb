module ClaimsReporting
  class MemberEnrollmentRoster < HealthBase
    phi_patient :member_id

    belongs_to :member_roster,
               primary_key: 'member_id',
               foreign_key: 'member_id',
               class_name: 'ClaimsReporting::MemberRoster'

    include ClaimsReporting::CsvHelpers
    def self.conflict_target
      ['member_id', 'span_start_date']
    end

    def self.schema_def
      <<~CSV.freeze
        ID,Field name,Description,Length,Data type,PRIVACY: former members
        1,member_id,Member's Medicaid identification number ,50,string,-
        2,performance_year,"Calendar/performance year during which the member is enrolled in a plan for the span segment (e.g. 2017). Spans are identified by calendar year except for CY 2018. Two separate spans are broken out to specify the period before and after the ACO program go-live in CY2018: (1) Between 1/1/18 and 2/28/18, the value is populated as “PreACO-2018” and (2) Between 3/1/18 and 12/31/18, the value is “PostACO-2018”.",50,string,-
        3,region,Managed care region a member resides,50,string,-
        4,service_area,Service area/geographic area covering member. A service area is within a managed care region,50,string,Redacted
        5,aco_pidsl,ACO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        6,aco_name,ACO name,255,string,-
        7,pcc_pidsl,PCC ID. PIDSL is a combination of provider ID and service location,50,string,-
        8,pcc_name,PCC name,255,string,-
        9,pcc_npi,PCC national provider identifier (NPI),50,string,-
        10,pcc_taxid,PCC tax identification number (TIN),50,string,-
        11,mco_pidsl,MCO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        12,mco_name,MCO name,50,string,-
        13,enrolled_flag,"Y/N flag if the span is active/current segment as of the last day of the reporting period. NOTE: the definition of this flag is different than that of ""enrolled_flag"" in the Membr roster.",50,string,-
        14,enroll_type,Enrollment type. Currently populates as null.,50,string,-
        15,enroll_stop_reason,Enrollment stop reason. Currently populates as null.,50,string,-
        16,rating_category_char_cd,Rating category,255,string,-
        17,ind_dds,Indicates whether member is affiliated with the Department of Development Services,50,string,Redacted
        18,ind_dmh,Indicates whether member is affiliated with the Department of Mental Health,50,string,Redacted
        19,ind_dta,Indicates whether member is affiliated with the Department of Transitional Assistance,50,string,Redacted
        20,ind_dss,Indicates whether member is affiliated with Department of Children and Families (formerly Department of Social Services),50,string,Redacted
        21,cde_hcb_waiver,Code to show member is enrolled in a home and community based services waiver,50,string,Redacted
        22,cde_waiver_category,More granular detail showing home and community based services waiver program member is enrolled in,50,string,Redacted
        23,span_start_date,Span start date,30,date (YYYY-MM-DD),-
        24,span_end_date,Span end date,30,date (YYYY-MM-DD),-
        25,span_mem_days,Span member days,10,int,-
        26,cp_prov_type,Community Partner (CP) Provider Type,255,string,-
        27,cp_plan_type,CP Assignment Plan Type,255,string,-
        28,cp_pidsl,CP entity ID. PIDSL is a combination of provider ID and service location,50,string,-
        29,cp_prov_name,CP Name,512,string,-
        30,cp_enroll_dt,Most recent CP enrollment date,30,date (YYYY-MM-DD),-
        31,cp_disenroll_dt,"Most recent CP disenrollment date. This field is bound by the reporting period, and any date that falls outside this reporting period will be nullified.",30,date (YYYY-MM-DD),-
        32,cp_start_rsn,Most recent CP start reason,255,string,-
        33,cp_stop_rsn,Most recent CP stop reason. Currently populates as null.,255,string,-
        34,ind_medicare_a,Indicates whether the member has Medicare Part A coverage ,50,string,-
        35,ind_medicare_b,Indicates whether the member has Medicare Part B coverage ,50,string,-
        36,tpl_coverage_cat,Coverage category type of the member’s verified TPL coverage,50,string,-
      CSV
    end
  end
end
