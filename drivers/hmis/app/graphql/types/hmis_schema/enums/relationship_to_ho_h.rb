###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::RelationshipToHoH < Types::BaseEnum
    description 'HUD RelationshipToHoH (3.15.1)'
    graphql_name 'RelationshipToHoH'

    with_enum_map Hmis::Hud::Enrollment.relationships_to_hoh_enum_map
  end
end
