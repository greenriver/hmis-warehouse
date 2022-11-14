# header
module Types
  class HmisSchema::Enums::DataCollectionStage < Types::BaseEnum
    description '5.03.1'
    graphql_name 'DataCollectionStage'
    value PROJECT_ENTRY, '(1) Project entry', value: 1
    value UPDATE, '(2) Update', value: 2
    value PROJECT_EXIT, '(3) Project exit', value: 3
    value ANNUAL_ASSESSMENT, '(5) Annual assessment', value: 5
    value POST_EXIT, '(6) Post-exit', value: 6
  end
end
