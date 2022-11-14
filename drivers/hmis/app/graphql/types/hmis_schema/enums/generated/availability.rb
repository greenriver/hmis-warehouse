# header
module Types
  class HmisSchema::Enums::Availability < Types::BaseEnum
    description '2.7.4'
    graphql_name 'Availability'
    value YEAR_ROUND, '(1) Year-round', value: 1
    value SEASONAL, '(2) Seasonal', value: 2
    value OVERFLOW, '(3) Overflow', value: 3
  end
end
