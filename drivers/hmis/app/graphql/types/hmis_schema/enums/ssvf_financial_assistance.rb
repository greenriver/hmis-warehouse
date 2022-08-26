###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SSVFFinancialAssistance < Types::BaseEnum
    description 'HUD SSVFFinancialAssistance (V3.3)'
    graphql_name 'SSVFFinancialAssistance'

    with_enum_map Hmis::Hud::Service.s_s_v_f_financial_assistance_enum_map
  end
end
