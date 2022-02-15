###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health::CpMembers
  class RosterFile < FileBase
    has_many :rosters, class_name: 'Health::CpMembers::Roster', foreign_key: :roster_file_id, inverse_of: :roster_file

    def label
      'CP Member Roster'
    end

    def columns
      {
        member_id: 'Member ID',
        nam_first: 'First Name',
        nam_last: 'Last Name',
        cp_pidsl: 'CP PID/SL',
        cp_name: 'CP Name',
        aco_pidsl: 'ACO PID/SL',
        aco_name: 'ACO Name',
        mco_pidsl: 'MCO PID/SL',
        mco_name: 'MCO Name',
        sex: 'Gender',
        date_of_birth: 'DOB',
        mailing_address_1: 'Mailing Address',
        mailing_address_2: 'Line 2',
        mailing_city: 'City',
        mailing_state: 'State',
        mailing_zip: 'Zip',
        residential_address_1: 'Residential Address',
        residential_address_2: 'Line 2',
        residential_city: 'City',
        residential_state: 'State',
        residential_zip: 'Zip',
        race: 'Race',
        phone_number: 'Phone Number',
        primary_language_s: 'Primary Spoken Language',
        primary_language_w: 'Primary Written Language',
        sdh_nss7_score: 'SDH NSS7 Score',
        sdh_homelessness: 'SDH Homelessness?',
        sdh_addresses_flag: 'SDH 3+ Addresses/1 year',
        sdh_other_disabled: 'SDH Other Disability?',
        sdh_spmi: 'SDH SPMI',
        raw_risk_score: 'Latest Raw SDH Risk Score',
        normalized_risk_score: 'Lastest Normalized SDH Risk Score',
        raw_dxcg_risk_score: 'Latest Raw DxCG Rusj Score',
        last_office_visit: 'Last Office Visit',
        last_ed_visit: 'Last ED Visit',
        last_ip_visit: 'Last In-Patient Visit',
        enrolled_flag: 'Enrolled?',
        enrollment_status: 'Enrollment Status',
        cp_claim_dt: 'Last CP Claim',
        qualifying_hcpcs: 'QA HCPCS for Enrollment',
        qualifying_hcpcs_nm: 'QA HCPCS Name',
        qualifying_dsc: 'QA Description',
        email: 'Email',
        head_of_household: 'Head of Household',
      }
    end

    private def model
      Health::CpMembers::Roster
    end

    private def expected_header
      'member_id,nam_first,nam_last,cp_pidsl,cp_name,aco_pidsl,aco_name,mco_pidsl,mco_name,sex,date_of_birth,mailing_address_1,mailing_address_2,mailing_city,mailing_state,mailing_zip,residential_address_1,residential_address_2,residential_city,residential_state,residential_zip,race,phone_number,primary_language_s,primary_language_w,sdh_nss7_score,sdh_homelessness,sdh_addresses_flag,sdh_other_disabled,sdh_spmi,raw_risk_score,normalized_risk_score,raw_dxcg_risk_score,last_office_visit,last_ed_visit,last_ip_visit,enrolled_flag,enrollment_status,cp_claim_dt,qualifying_hcpcs,qualifying_hcpcs_nm,qualifying_dsc,email,head_of_household'
    end
  end
end
