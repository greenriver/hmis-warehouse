# header
module Types
  class HmisSchema::Enums::SourceType < Types::BaseEnum
    description '1.9'
    graphql_name 'SourceType'
    value COC_HMIS, '(1) CoC HMIS', value: 1
    value STANDALONE_AGENCY_SPECIFIC_APPLICATION, '(2) Standalone/agency-specific application', value: 2
    value DATA_WAREHOUSE, '(3) Data warehouse', value: 3
    value OTHER, '(4) Other', value: 4
  end
end
