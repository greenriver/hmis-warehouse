# header
module Types
  class HmisSchema::Enums::AddressDataQuality < Types::BaseEnum
    description 'V5.5'
    graphql_name 'AddressDataQuality'
    value FULL_ADDRESS, '(1) Full address', value: 1
    value INCOMPLETE_OR_ESTIMATED_ADDRESS, '(2) Incomplete or estimated address', value: 2
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
