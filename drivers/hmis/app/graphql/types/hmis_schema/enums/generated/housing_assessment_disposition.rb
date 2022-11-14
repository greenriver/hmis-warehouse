# header
module Types
  class HmisSchema::Enums::HousingAssessmentDisposition < Types::BaseEnum
    description '4.18.1'
    graphql_name 'HousingAssessmentDisposition'
    value REFERRED_TO_EMERGENCY_SHELTER_SAFE_HAVEN, '(1) Referred to emergency shelter/safe haven', value: 1
    value REFERRED_TO_TRANSITIONAL_HOUSING, '(2) Referred to transitional housing', value: 2
    value REFERRED_TO_RAPID_RE_HOUSING, '(3) Referred to rapid re-housing', value: 3
    value REFERRED_TO_PERMANENT_SUPPORTIVE_HOUSING, '(4) Referred to permanent supportive housing', value: 4
    value REFERRED_TO_HOMELESSNESS_PREVENTION, '(5) Referred to homelessness prevention', value: 5
    value REFERRED_TO_STREET_OUTREACH, '(6) Referred to street outreach', value: 6
    value REFERRED_TO_OTHER_CONTINUUM_PROJECT_TYPE, '(7) Referred to other continuum project type', value: 7
    value REFERRED_TO_A_HOMELESSNESS_DIVERSION_PROGRAM, '(8) Referred to a homelessness diversion program', value: 8
    value UNABLE_TO_REFER_ACCEPT_WITHIN_CONTINUUM_INELIGIBLE_FOR_CONTINUUM_PROJECTS, '(9) Unable to refer/accept within continuum; ineligible for continuum projects', value: 9
    value UNABLE_TO_REFER_ACCEPT_WITHIN_CONTINUUM_CONTINUUM_SERVICES_UNAVAILABLE, '(10) Unable to refer/accept within continuum; continuum services unavailable', value: 10
    value REFERRED_TO_OTHER_COMMUNITY_PROJECT_NON_CONTINUUM, '(11) Referred to other community project (non-continuum)', value: 11
    value APPLICANT_DECLINED_REFERRAL_ACCEPTANCE, '(12) Applicant declined referral/acceptance', value: 12
    value APPLICANT_TERMINATED_ASSESSMENT_PRIOR_TO_COMPLETION, '(13) Applicant terminated assessment prior to completion', value: 13
    value OTHER_SPECIFY, '(14) Other/specify', value: 14
  end
end
