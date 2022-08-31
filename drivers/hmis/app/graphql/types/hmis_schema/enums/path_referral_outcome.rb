###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::PATHReferralOutcome < Types::BaseEnum
    description 'HUD PATHReferralOutcome (P2.A)'
    graphql_name 'PATHReferralOutcome'

    with_enum_map Hmis::Hud::Service.p_a_t_h_referral_outcome_enum_map
  end
end
