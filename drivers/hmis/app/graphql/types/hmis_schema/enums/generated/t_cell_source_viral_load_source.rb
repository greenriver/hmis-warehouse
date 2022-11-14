# header
module Types
  class HmisSchema::Enums::TCellSourceViralLoadSource < Types::BaseEnum
    description 'W4.B'
    graphql_name 'TCellSourceViralLoadSource'
    value MEDICAL_REPORT, '(1) Medical Report', value: 1
    value CLIENT_REPORT, '(2) Client Report', value: 2
    value OTHER, '(3) Other', value: 3
  end
end
