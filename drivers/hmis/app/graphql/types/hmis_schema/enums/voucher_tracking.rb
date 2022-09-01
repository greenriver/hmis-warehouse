###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::VoucherTracking < Types::BaseEnum
    description 'HUD VoucherTracking (V8.1)'
    graphql_name 'VoucherTracking'

    with_enum_map Hmis::Hud::Service.voucher_tracking_enum_map
  end
end
