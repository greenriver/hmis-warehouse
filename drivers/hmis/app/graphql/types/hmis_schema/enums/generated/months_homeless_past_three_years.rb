# header
module Types
  class HmisSchema::Enums::MonthsHomelessPastThreeYears < Types::BaseEnum
    description '3.917.5'
    graphql_name 'MonthsHomelessPastThreeYears'
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
    value NUM_1, '(101) 1', value: 101
    value NUM_2, '(102) 2', value: 102
    value NUM_3, '(103) 3', value: 103
    value NUM_4, '(104) 4', value: 104
    value NUM_5, '(105) 5', value: 105
    value NUM_6, '(106) 6', value: 106
    value NUM_7, '(107) 7', value: 107
    value NUM_8, '(108) 8', value: 108
    value NUM_9, '(109) 9', value: 109
    value NUM_10, '(110) 10', value: 110
    value NUM_11, '(111) 11', value: 111
    value NUM_12, '(112) 12', value: 112
    value MORE_THAN_12_MONTHS, '(113) More than 12 months', value: 113
  end
end
