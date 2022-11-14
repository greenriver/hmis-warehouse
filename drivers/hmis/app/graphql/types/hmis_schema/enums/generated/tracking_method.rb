# header
module Types
  class HmisSchema::Enums::TrackingMethod < Types::BaseEnum
    description '2.5.1'
    graphql_name 'TrackingMethod'
    value ENTRY_EXIT_DATE, '(0) Entry/Exit Date', value: 0
    value NIGHT_BY_NIGHT, '(3) Night-by-Night', value: 3
  end
end
