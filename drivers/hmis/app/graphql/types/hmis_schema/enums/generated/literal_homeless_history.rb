# header
module Types
  class HmisSchema::Enums::LiteralHomelessHistory < Types::BaseEnum
    description 'V7.C'
    graphql_name 'LiteralHomelessHistory'
    value MOST_RECENT_EPISODE_OCCURRED_IN_THE_LAST_YEAR, '(0) Most recent episode occurred in the last year', value: 0
    value MOST_RECENT_EPISODE_OCCURRED_MORE_THAN_ONE_YEAR_AGO, '(1) Most recent episode occurred more than one year ago', value: 1
    value NONE, '(2) None', value: 2
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
