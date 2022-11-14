# header
module Types
  class HmisSchema::Enums::RaceNone < Types::BaseEnum
    description '1.6'
    graphql_name 'RaceNone'
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
