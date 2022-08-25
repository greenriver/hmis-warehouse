###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ProbSolDivRRResult < Types::BaseEnum
    description 'HUD ProbSolDivRRResult'
    graphql_name 'ProbSolDivRRResult'

    with_enum_map Hmis::Hud::Event.prob_sol_div_rr_result_enum_map
  end
end
