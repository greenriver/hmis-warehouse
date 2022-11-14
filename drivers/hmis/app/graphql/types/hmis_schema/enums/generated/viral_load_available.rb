# header
module Types
  class HmisSchema::Enums::ViralLoadAvailable < Types::BaseEnum
    description 'W4.3'
    graphql_name 'ViralLoadAvailable'
    value NOT_AVAILABLE, '(0) Not available', value: 0
    value AVAILABLE, '(1) Available', value: 1
    value UNDETECTABLE, '(2) Undetectable', value: 2
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
