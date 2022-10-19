###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::BedType < Types::BaseEnum
    description 'HUD Bed Type (2.7.3)'
    graphql_name 'BedType'

    with_enum_map Hmis::Hud::Inventory.bed_type_enum_map
  end
end
