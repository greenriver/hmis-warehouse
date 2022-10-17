###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::HouseholdType < Types::BaseEnum
    description 'HUD Household Type (2.7.2)'
    graphql_name 'HouseholdType'

    with_enum_map Hmis::Hud::Inventory.household_type_enum_map
  end
end
