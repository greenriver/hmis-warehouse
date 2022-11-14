# header
module Types
  class HmisSchema::Enums::AssessmentType < Types::BaseEnum
    description '4.19.3'
    graphql_name 'AssessmentType'
    value PHONE, '(1) Phone', value: 1
    value VIRTUAL, '(2) Virtual', value: 2
    value IN_PERSON, '(3) In Person', value: 3
  end
end
