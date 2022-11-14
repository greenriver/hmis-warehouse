# header
module Types
  class HmisSchema::Enums::AssessmentLevel < Types::BaseEnum
    description '4.19.4'
    graphql_name 'AssessmentLevel'
    value CRISIS_NEEDS_ASSESSMENT, '(1) Crisis Needs Assessment', value: 1
    value HOUSING_NEEDS_ASSESSMENT, '(2) Housing Needs Assessment', value: 2
  end
end
