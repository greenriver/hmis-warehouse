# header
module Types
  class HmisSchema::Enums::AftercareProvided < Types::BaseEnum
    description 'R20.2'
    graphql_name 'AftercareProvided'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value CLIENT_REFUSED, '(9) Client refused', value: 9
  end
end
