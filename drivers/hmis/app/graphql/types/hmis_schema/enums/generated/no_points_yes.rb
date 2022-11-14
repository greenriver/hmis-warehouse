# header
module Types
  class HmisSchema::Enums::NoPointsYes < Types::BaseEnum
    description 'V7.1'
    graphql_name 'NoPointsYes'
    value NO_0_POINTS, '(0) No (0 points)', value: 0
    value YES, '(1) Yes', value: 1
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
