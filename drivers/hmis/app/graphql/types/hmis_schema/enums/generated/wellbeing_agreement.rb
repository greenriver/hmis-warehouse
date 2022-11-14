# header
module Types
  class HmisSchema::Enums::WellbeingAgreement < Types::BaseEnum
    description 'C1.1'
    graphql_name 'WellbeingAgreement'
    value STRONGLY_DISAGREE, '(0) Strongly disagree', value: 0
    value SOMEWHAT_DISAGREE, '(1) Somewhat disagree', value: 1
    value NEITHER_AGREE_NOR_DISAGREE, '(2) Neither agree nor disagree', value: 2
    value SOMEWHAT_AGREE, '(3) Somewhat agree', value: 3
    value STRONGLY_AGREE, '(4) Strongly agree', value: 4
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
