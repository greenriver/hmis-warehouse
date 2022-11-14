# header
module Types
  class HmisSchema::Enums::NoYesMissing < Types::BaseEnum
    description '1.7'
    graphql_name 'NoYesMissing'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
