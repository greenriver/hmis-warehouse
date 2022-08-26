###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::HOPWAFinancialAssistance < Types::BaseEnum
    description 'HUD HOPWAFinancialAssistance'
    graphql_name 'HOPWAFinancialAssistance'

    with_enum_map Hmis::Hud::Service.h_o_p_w_a_financial_assistance_enum_map
  end
end
