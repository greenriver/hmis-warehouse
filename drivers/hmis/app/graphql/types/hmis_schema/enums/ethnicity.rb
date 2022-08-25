###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Ethnicity < Types::BaseEnum
    description 'HUD Ethnicity'
    graphql_name 'Ethnicity'

    with_enum_map Hmis::Hud::Client.ethnicity_enum_map, prefix: 'ETHNICITY_'
  end
end
