# header
module Types
  class HmisSchema::Enums::ResidencePriorLengthOfStay < Types::BaseEnum
    description '3.917.2'
    graphql_name 'ResidencePriorLengthOfStay'
    value ONE_WEEK_OR_MORE_BUT_LESS_THAN_ONE_MONTH, '(2) One week or more, but less than one month', value: 2
    value ONE_MONTH_OR_MORE_BUT_LESS_THAN_90_DAYS, '(3) One month or more, but less than 90 days', value: 3
    value NUM_90_DAYS_OR_MORE_BUT_LESS_THAN_ONE_YEAR, '(4) 90 days or more but less than one year', value: 4
    value ONE_YEAR_OR_LONGER, '(5) One year or longer', value: 5
    value CLIENT_DOESN_T_KNOW, "(8) Client doesn't know", value: 8
    value CLIENT_REFUSED, '(9) Client refused', value: 9
    value ONE_NIGHT_OR_LESS, '(10) One night or less', value: 10
    value TWO_TO_SIX_NIGHTS, '(11) Two to six nights', value: 11
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
