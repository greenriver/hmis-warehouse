# header
module Types
  class HmisSchema::Enums::PATHServices < Types::BaseEnum
    description 'P1.2'
    graphql_name 'PATHServices'
    value RE_ENGAGEMENT, '(1) Re-engagement', value: 1
    value SCREENING, '(2) Screening', value: 2
    value HABILITATION_REHABILITATION, '(3) Habilitation/rehabilitation', value: 3
    value COMMUNITY_MENTAL_HEALTH, '(4) Community mental health', value: 4
    value SUBSTANCE_USE_TREATMENT, '(5) Substance use treatment', value: 5
    value CASE_MANAGEMENT, '(6) Case management', value: 6
    value RESIDENTIAL_SUPPORTIVE_SERVICES, '(7) Residential supportive services', value: 7
    value HOUSING_MINOR_RENOVATION, '(8) Housing minor renovation', value: 8
    value HOUSING_MOVING_ASSISTANCE, '(9) Housing moving assistance', value: 9
    value HOUSING_ELIGIBILITY_DETERMINATION, '(10) Housing eligibility determination', value: 10
    value SECURITY_DEPOSITS, '(11) Security deposits', value: 11
    value ONE_TIME_RENT_FOR_EVICTION_PREVENTION, '(12) One-time rent for eviction prevention', value: 12
    value CLINICAL_ASSESSMENT, '(14) Clinical assessment', value: 14
  end
end
