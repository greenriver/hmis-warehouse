# header
module Types
  class HmisSchema::Enums::Gender < Types::BaseEnum
    description '3.6.1'
    graphql_name 'Gender'
    value FEMALE, '(0) Female', value: 0
    value MALE, '(1) Male', value: 1
    value A_GENDER_OTHER_THAN_SINGULARLY_FEMALE_OR_MALE_E_G_NON_BINARY_GENDERFLUID_AGENDER_CULTURALLY_SPECIFIC_GENDER, '(4) A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)', value: 4
    value TRANSGENDER, '(5) Transgender', value: 5
    value QUESTIONING, '(6) Questioning', value: 6
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
