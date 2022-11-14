# header
module Types
  class HmisSchema::Enums::PrioritizationStatus < Types::BaseEnum
    description '4.19.7'
    graphql_name 'PrioritizationStatus'
    value PLACED_ON_PRIORITIZATION_LIST, '(1) Placed on prioritization list', value: 1
    value NOT_PLACED_ON_PRIORITIZATION_LIST, '(2) Not placed on prioritization list', value: 2
  end
end
