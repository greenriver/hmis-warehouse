###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DataCollectionStage < Types::BaseEnum
    description '5.03.1'
    graphql_name 'DataCollectionStage'
    value 'PROJECT_ENTRY', '(1) Project entry', value: 1
    value 'UPDATE', '(2) Update', value: 2
    value 'PROJECT_EXIT', '(3) Project exit', value: 3
    value 'ANNUAL_ASSESSMENT', '(5) Annual assessment', value: 5
    value 'POST_EXIT', '(6) Post-exit', value: 6
  end
end
