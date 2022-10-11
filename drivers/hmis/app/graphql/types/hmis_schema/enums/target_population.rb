###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::TargetPopulation < Types::BaseEnum
    description 'HUD TargetPopulation (2.02.8)'
    graphql_name 'TargetPopulation'

    with_enum_map Hmis::Hud::Project.target_population_enum_map
  end
end
