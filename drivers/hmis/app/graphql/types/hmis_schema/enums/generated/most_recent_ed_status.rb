# header
module Types
  class HmisSchema::Enums::MostRecentEdStatus < Types::BaseEnum
    description 'C3.A'
    graphql_name 'MostRecentEdStatus'
    value K12_GRADUATED_FROM_HIGH_SCHOOL, '(0) K12: Graduated from high school', value: 0
    value K12_OBTAINED_GED, '(1) K12: Obtained GED', value: 1
    value K12_DROPPED_OUT, '(2) K12: Dropped out', value: 2
    value K12_SUSPENDED, '(3) K12: Suspended', value: 3
    value K12_EXPELLED, '(4) K12: Expelled', value: 4
    value HIGHER_EDUCATION_PURSUING_A_CREDENTIAL_BUT_NOT_CURRENTLY_ATTENDING, '(5) Higher education: Pursuing a credential but not currently attending', value: 5
    value HIGHER_EDUCATION_DROPPED_OUT, '(6) Higher education: Dropped out', value: 6
    value HIGHER_EDUCATION_OBTAINED_A_CREDENTIAL_DEGREE, '(7) Higher education: Obtained a credential/degree', value: 7
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
