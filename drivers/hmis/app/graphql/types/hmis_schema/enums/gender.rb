###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Gender < Types::BaseEnum
    description 'HUD Gender'
    graphql_name 'Gender'

    with_enum_map Hmis::Hud::Client.gender_enum_map, prefix: 'GENDER_'
  end
end
