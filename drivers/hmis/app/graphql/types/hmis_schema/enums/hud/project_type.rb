###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ProjectType < Types::BaseEnum
    description '2.4.2'
    graphql_name 'ProjectType'
    value EMERGENCY_SHELTER, '(1) Emergency Shelter', value: 1
    value TRANSITIONAL_HOUSING, '(2) Transitional Housing', value: 2
    value PH_PERMANENT_SUPPORTIVE_HOUSING, '(3) PH - Permanent Supportive Housing', value: 3
    value STREET_OUTREACH, '(4) Street Outreach', value: 4
    value SERVICES_ONLY, '(6) Services Only', value: 6
    value OTHER, '(7) Other', value: 7
    value SAFE_HAVEN, '(8) Safe Haven', value: 8
    value PH_HOUSING_ONLY, '(9) PH - Housing Only', value: 9
    value PH_HOUSING_WITH_SERVICES_NO_DISABILITY_REQUIRED_FOR_ENTRY, '(10) PH - Housing with Services (no disability required for entry)', value: 10
    value DAY_SHELTER, '(11) Day Shelter', value: 11
    value HOMELESSNESS_PREVENTION, '(12) Homelessness Prevention', value: 12
    value PH_RAPID_RE_HOUSING, '(13) PH - Rapid Re-Housing', value: 13
    value COORDINATED_ENTRY, '(14) Coordinated Entry', value: 14
  end
end
