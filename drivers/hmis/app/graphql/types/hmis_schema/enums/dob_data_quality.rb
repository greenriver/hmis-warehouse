###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::DOBDataQuality < Types::BaseEnum
    description 'HUD DOB Data Quality (3.03.2)'
    graphql_name 'DOBDataQuality'

    with_enum_map Hmis::Hud::Client.dob_data_quality_enum_map, prefix: 'DOB_'
  end
end
