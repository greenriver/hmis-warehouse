###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::NameDataQuality < Types::BaseEnum
    description 'HUD NameDataQuality (3.01.5)'
    graphql_name 'NameDataQuality'

    with_enum_map Hmis::Hud::Client.name_data_quality_enum_map, prefix: 'NAME_'
  end
end
