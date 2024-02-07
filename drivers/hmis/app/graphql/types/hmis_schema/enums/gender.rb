###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Gender < Types::BaseEnum
    description 'HUD Gender (1.7)'
    graphql_name 'Gender'

    with_enum_map Hmis::Hud::Client.gender_enum_map
  end
end
