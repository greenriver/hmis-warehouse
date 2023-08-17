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
    # value 'ES', 'Emergency Shelter', value: 1
    # value 'TH', 'Transitional Housing', value: 2
    # value 'PSH', 'Permanent Supportive Housing', value: 3
    # value 'SO', 'Street Outreach', value: 4
    # value 'SERVICES_ONLY', 'Services Only', value: 6
    # value 'OTHER', 'Other', value: 7
    # value 'SH', 'Safe Haven', value: 8
    # value 'OPH', 'Permanent Housing Only', value: 9
    # value 'PH', 'Permanent Housing', value: 10
    # value 'DAY_SHELTER', 'Day Shelter', value: 11
    # value 'PREVENTION', 'Homelessness Prevention', value: 12
    # value 'RRH', 'Rapid Re-Housing', value: 13
    # value 'CE', 'Coordinated Entry', value: 14
    invalid_value
  end
end
