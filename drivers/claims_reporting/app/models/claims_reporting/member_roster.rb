###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class MemberRoster < HealthBase
    include ArelHelper

    phi_patient :member_id
    belongs_to :patient, foreign_key: :member_id, class_name: 'Health::Patient', primary_key: :medicaid_id, optional: true

    has_one :diagnosis_classification,
            primary_key: 'member_id',
            foreign_key: 'member_id',
            class_name: 'ClaimsReporting::MemberDiagnosisClassification'

    has_many :enrollment_rosters,
             primary_key: 'member_id',
             foreign_key: 'member_id',
             class_name: 'ClaimsReporting::MemberEnrollmentRoster'

    has_many :medical_claims,
             primary_key: 'member_id',
             foreign_key: 'member_id',
             class_name: 'ClaimsReporting::MedicalClaim'

    include ClaimsReporting::CsvHelpers

    # Members with a ::Health::PatientReferral who
    # have been engaged for a range of total days in
    # enrollment spans starting by the provided date
    scope :engaged_for, ->(range, date = Date.current) do
      where(
        member_id: ClaimsReporting::MemberEnrollmentRoster.where(
          ['span_start_date <= ?', date],
        ).engaged_for(range).select(:member_id),
      )
    end

    # Having a total of 0 engaged days
    scope :pre_engaged, ->(date = Date.current) do
      engaged_for(0..0, date)
    end

    # Anyone who exists in member roster, but not in Health::PatientReferral
    scope :pre_assigned, ->(date = Date.current) do
      where.not(
        member_id: ::Health::PatientReferral.where(hpr_t[:enrollment_start_date].lt(date)).
          select(:medicaid_id),
      )
    end

    def self.conflict_target
      ['member_id']
    end

    def self.schema_def
      <<~CSV.freeze
        ID,Field name,Description,Length,Data type,PRIVACY: former members,PRIVACY: virtually assigned members2,PRIVACY: former members3
        1,member_id,Member's Medicaid identification number.,50,string,-,Randomize,-
        2,nam_first,First name,255,string,Redacted,Redacted,Redacted
        3,nam_last,Last name,255,string,Redacted,Redacted,Redacted
        4,cp_pidsl,CP Entity ID. PIDSL is a combination of provider ID and service location,50,string,-,,
        5,cp_name,CP name,255,string,-,,
        6,aco_pidsl,ACO Entity ID. PIDSL is a combination of provider ID and service location,50,string,-,-,-
        7,aco_name,ACO name,255,string,-,-,-
        8,mco_pidsl,MCO Entity ID. PIDSL is a combination of provider ID and service location,50,string,-,-,-
        9,mco_name,MCO name,50,string,-,-,-
        10,sex,Sex,50,string,-,-,-
        11,date_of_birth,Date of birth,30,date,-,Redacted,-
        12,mailing_address_1,Mailing address 1,512,string,Redacted,Redacted,Redacted
        13,mailing_address_2,Mailing address 2,512,string,Redacted,Redacted,Redacted
        14,mailing_city,Mailing city,255,string,Redacted,Redacted,Redacted
        15,mailing_state,Mailing state,255,string,Redacted,Redacted,Redacted
        16,mailing_zip,Mailing zip,50,string,Redacted,Redacted,Redacted
        17,residential_address_1,Residential address 1,512,string,Redacted,Redacted,Redacted
        18,residential_address_2,Residential address 2,512,string,Redacted,Redacted,Redacted
        19,residential_city,Residential city,255,string,Redacted,Redacted,Redacted
        20,residential_state,Residential state,255,string,Redacted,Redacted,Redacted
        21,residential_zip,Residential zip,50,string,Redacted,Redacted,Redacted
        22,race,Race,50,string,Redacted,Redacted,Redacted
        23,phone_number,Phone number,50,string,Redacted,Redacted,Redacted
        24,primary_language_s,Primary language - spoken,255,string,Redacted,Redacted,Redacted
        25,primary_language_w,Primary language - written. Currently populates as null.,255,string,Redacted,Redacted,Redacted
        26,sdh_nss7_score ,Social determinant of health - NSS7 score*,50,string,-,-,-
        27,sdh_homelessness,Social determinant of health - Homelessness*,50,string,-,-,-
        28,sdh_addresses_flag,Social determinant of health - 3+ addresses in Y/N 1yr flag*,50,string,-,-,-
        29,sdh_other_disabled,Social determinant of health - Other disabled*,50,string,-,-,-
        30,sdh_spmi,Social determinant of health - severe persistent mental illness (SPMI)*,50,string,-,-,-
        31,raw_risk_score,"Latest Social Determinants of Health (SDH) risk score, including DxCG score and SDH components.* ",50,string,-,-,-
        32,normalized_risk_score,"Latest SDH risk score, for member's with <6 months managed care eligible experience their score is blended with the plan-age--sex-RC-plan selection average. All scores are then normalized to the member's rating category and region.*",50,string,-,-,-
        33,raw_dxcg_risk_score,Latest DxCG risk score for the member*,50,string,-,-,-
        34,last_office_visit,"Member's last office visit; non-inpatient, non-ED. Currently populates as null.",30,date (YYYY-MM-DD),Redacted,Redacted,Redacted
        35,last_ed_visit,Member's last emergency department visit,30,date (YYYY-MM-DD),Redacted,Redacted,Redacted
        36,last_ip_visit,Member's last inpatient admission. Currently populates as null.,30,date (YYYY-MM-DD),Redacted,Redacted,Redacted
        37,enrolled_flag,Y/N flag depending on if member is current with your entity,50,string,,,
        38,enrollment_status,"Enrollment status with your entity (new, continuous, terminated)",50,string,-,-,-
        39,cp_claim_dt,Date of most recent Community Partner (CP) claim,30,date (YYYY-MM-DD),-,-,-
        40,qualifying_hcpcs,Qualifying activity HCPCS (procedure code) for CP enrollment,50,string,-,-,-
        41,qualifying_hcpcs_nm,Qualifying activity HCPCS (procedure code) description for CP enrollment,255,string,-,-,-
        42,qualifying_dsc,Qualifying activity description,512,string,-,-,-
        43,email,Email,512,string,Redacted,Redacted,Redacted
        44,head_of_household,Head of household,512,string,Redacted,Redacted,Redacted
        45,sdh_smi,,50,string
      CSV
    end
  end
end
