###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::BedNight < Types::BaseEnum
    description 'HUD BedNight'
    graphql_name 'BedNight'

    with_enum_map Hmis::Hud::Service.bed_night_enum_map
  end
end
