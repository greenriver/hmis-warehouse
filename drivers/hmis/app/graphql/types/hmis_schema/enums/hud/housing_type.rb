###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::HousingType < Types::BaseEnum
    description '2.02.D'
    graphql_name 'HousingType'
    value 'SITE_BASED_SINGLE_SITE', '(1) Site-based - single site', value: 1
    value 'SITE_BASED_CLUSTERED_MULTIPLE_SITES', '(2) Site-based - clustered / multiple sites', value: 2
    value 'TENANT_BASED_SCATTERED_SITE', '(3) Tenant-based - scattered site', value: 3
  end
end
