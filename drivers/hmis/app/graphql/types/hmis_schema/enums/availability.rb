###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::Availability < Types::BaseEnum
    description 'HUD Availability (2.7.4)'
    graphql_name 'Availability'

    with_enum_map Hmis::Hud::Inventory.availability_enum_map
  end
end
