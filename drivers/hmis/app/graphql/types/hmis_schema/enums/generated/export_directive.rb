# header
module Types
  class HmisSchema::Enums::ExportDirective < Types::BaseEnum
    description '1.2'
    graphql_name 'ExportDirective'
    value DELTA_REFRESH, '(1) Delta refresh', value: 1
    value FULL_REFRESH, '(2) Full refresh', value: 2
    value OTHER, '(3) Other', value: 3
  end
end
