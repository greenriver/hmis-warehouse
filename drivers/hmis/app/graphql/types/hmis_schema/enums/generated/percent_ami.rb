# header
module Types
  class HmisSchema::Enums::PercentAMI < Types::BaseEnum
    description 'V4.1'
    graphql_name 'PercentAMI'
    value LESS_THAN_30, '(1) Less than 30%', value: 1
    value NUM_30_TO_50, '(2) 30% to 50%', value: 2
    value GREATER_THAN_50, '(3) Greater than 50%', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
