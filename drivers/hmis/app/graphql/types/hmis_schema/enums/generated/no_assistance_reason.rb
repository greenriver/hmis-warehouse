# header
module Types
  class HmisSchema::Enums::NoAssistanceReason < Types::BaseEnum
    description 'W3'
    graphql_name 'NoAssistanceReason'
    value APPLIED_DECISION_PENDING, '(1) Applied; decision pending', value: 1
    value APPLIED_CLIENT_NOT_ELIGIBLE, '(2) Applied; client not eligible', value: 2
    value CLIENT_DID_NOT_APPLY, '(3) Client did not apply', value: 3
    value INSURANCE_TYPE_NOT_APPLICABLE_FOR_THIS_CLIENT, '(4) Insurance type not applicable for this client', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
