# header
module Types
  class HmisSchema::Enums::ExitAction < Types::BaseEnum
    description '4.36.1'
    graphql_name 'ExitAction'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value CLIENT_REFUSED, '(9) Client refused', value: 9
  end
end
