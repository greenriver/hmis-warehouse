###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::TrackingMethod < Types::BaseEnum
    description 'HUD TrackingMethod (2.02.C)'
    graphql_name 'TrackingMethod'

    with_enum_map Hmis::Hud::Project.tracking_methods_enum_map
  end
end
