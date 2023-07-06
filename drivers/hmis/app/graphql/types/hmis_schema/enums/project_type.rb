###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ProjectType < Types::BaseEnum
    description 'HUD Project Types'
    graphql_name 'ProjectType'

    with_enum_map Hmis::Hud::Project.project_type_enum_map, prefix_description_with_key: true
    invalid_value
  end
end
