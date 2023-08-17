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

    HudUtility.project_types.each do |id, description|
      key = HudUtility.project_type_briefs[id].gsub(/ -?\s?/, '_').gsub('/', '_').upcase
      value key, description, value: id
    end
    invalid_value
  end
end
