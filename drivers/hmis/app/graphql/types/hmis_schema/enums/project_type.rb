###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ProjectType < Types::BaseEnum
    description 'HUD Project Types'
    graphql_name 'ProjectType'

    HudUtility2026.hmis_project_type_keys.each do |number, identifier|
      description = HudUtility2026.project_type(number)
      description = description.sub(/\s*\(.+\)$/, '')

      value identifier, description, value: number
    end
    invalid_value
  end
end
