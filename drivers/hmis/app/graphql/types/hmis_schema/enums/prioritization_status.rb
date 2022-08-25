###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::PrioritizationStatus < Types::BaseEnum
    description 'HUD PrioritizationStatus'
    graphql_name 'PrioritizationStatus'

    with_enum_map Hmis::Hud::Assessment.prioritization_statuses_enum_map
  end
end
