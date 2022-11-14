# header
module Types
  class HmisSchema::Enums::NoYesReasonsForMissingData < Types::BaseEnum
    description '1.8'
    graphql_name 'NoYesReasonsForMissingData'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
