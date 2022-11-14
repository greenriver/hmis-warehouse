# header
module Types
  class HmisSchema::Enums::HousingStatus < Types::BaseEnum
    description '4.1.1'
    graphql_name 'HousingStatus'
    value CATEGORY_1_HOMELESS, '(1) Category 1 - Homeless', value: 1
    value CATEGORY_2_AT_IMMINENT_RISK_OF_LOSING_HOUSING, '(2) Category 2 - At imminent risk of losing housing', value: 2
    value AT_RISK_OF_HOMELESSNESS, '(3) At-risk of homelessness', value: 3
    value STABLY_HOUSED, '(4) Stably housed', value: 4
    value CATEGORY_3_HOMELESS_ONLY_UNDER_OTHER_FEDERAL_STATUTES, '(5) Category 3 - Homeless only under other federal statutes', value: 5
    value CATEGORY_4_FLEEING_DOMESTIC_VIOLENCE, '(6) Category 4 - Fleeing domestic violence', value: 6
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
