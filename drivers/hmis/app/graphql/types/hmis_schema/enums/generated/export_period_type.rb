# header
module Types
  class HmisSchema::Enums::ExportPeriodType < Types::BaseEnum
    description '1.1'
    graphql_name 'ExportPeriodType'
    value UPDATED, '(1) Updated', value: 1
    value EFFECTIVE, '(2) Effective', value: 2
    value REPORTING_PERIOD, '(3) Reporting period', value: 3
    value OTHER, '(4) Other', value: 4
  end
end
