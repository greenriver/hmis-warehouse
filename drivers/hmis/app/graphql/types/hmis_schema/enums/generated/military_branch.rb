# header
module Types
  class HmisSchema::Enums::MilitaryBranch < Types::BaseEnum
    description 'V1.11'
    graphql_name 'MilitaryBranch'
    value ARMY, '(1) Army', value: 1
    value AIR_FORCE, '(2) Air Force', value: 2
    value NAVY, '(3) Navy', value: 3
    value MARINES, '(4) Marines', value: 4
    value COAST_GUARD, '(6) Coast Guard', value: 6
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
