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
    # HudLists.project_type_map.each do |id, description|
    #   brief = HudLists.project_type_brief_map[id].gsub(/\s-?\s?/, '_').upcase
    #   value brief, "(#{id}) #{description}", value: id
    # end

    invalid_value
  end
end
