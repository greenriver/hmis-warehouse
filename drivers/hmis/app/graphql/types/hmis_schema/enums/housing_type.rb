###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::HousingType < Types::BaseEnum
    description 'HUD HousingType (2.02.D)'
    graphql_name 'HousingType'

    with_enum_map Hmis::Hud::Project.housing_type_enum_map
  end
end
