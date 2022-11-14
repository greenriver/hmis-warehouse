# header
module Types
  class HmisSchema::Enums::YouthAgeGroup < Types::BaseEnum
    description '2.7.B'
    graphql_name 'YouthAgeGroup'
    value ONLY_UNDER_AGE_18, '(1) Only under age 18', value: 1
    value ONLY_AGES_18_TO_24, '(2) Only ages 18 to 24', value: 2
    value ONLY_YOUTH_UNDER_AGE_24_BOTH_OF_THE_ABOVE, '(3) Only youth under age 24 (both of the above)', value: 3
  end
end
