###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::DataCollectionStage < Types::BaseEnum
    description 'HUD Data Collection Stage (5.03.1)'
    graphql_name 'DataCollectionStage'

    with_enum_map Hmis::Form::AssessmentDetail.data_collection_stage_enum_map
  end
end
