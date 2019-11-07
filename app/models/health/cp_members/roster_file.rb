###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health::CpMembers
  class RosterFile < FileBase
    has_many :rosters, class_name: 'Health::CpMembers::Roster', inverse_of: :roster_file

    private def model
      Health::CpMembers::Roster
    end

    private def expected_header
      'member_id,nam_first,nam_last,cp_pidsl,cp_name,aco_pidsl,aco_name,mco_pidsl,mco_name,sex,date_of_birth,mailing_address_1,mailing_address_2,mailing_city,mailing_state,mailing_zip,residential_address_1,residential_address_2,residential_city,residential_state,residential_zip,race,phone_number,primary_language_s,primary_language_w,sdh_nss7_score,sdh_homelessness,sdh_addresses_flag,sdh_other_disabled,sdh_spmi,raw_risk_score,normalized_risk_score,raw_dxcg_risk_score,last_office_visit,last_ed_visit,last_ip_visit,enrolled_flag,enrollment_status,cp_claim_dt,qualifying_hcpcs,qualifying_hcpcs_nm,qualifying_dsc,email,head_of_household'
    end
  end
end