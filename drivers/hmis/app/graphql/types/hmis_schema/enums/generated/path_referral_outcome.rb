# header
module Types
  class HmisSchema::Enums::PATHReferralOutcome < Types::BaseEnum
    description '4.16.A1'
    graphql_name 'PATHReferralOutcome'
    value ATTAINED, '(1) Attained', value: 1
    value NOT_ATTAINED, '(2) Not attained', value: 2
    value UNKNOWN, '(3) Unknown', value: 3
  end
end
