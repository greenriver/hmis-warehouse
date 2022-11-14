# header
module Types
  class HmisSchema::Enums::AdHocYesNo < Types::BaseEnum
    description 'ad_hoc_yes_no'
    graphql_name 'AdHocYesNo'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value DON_T_KNOW, "(8) Don't Know", value: 8
    value REFUSED, '(9) Refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
