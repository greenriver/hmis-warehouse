###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # A member of a household that is referred for services
  class ReferralClient < HmisExternalApisBase
    self.table_name = 'hmis_external_referral_clients'
    belongs_to :referral, class_name: 'HmisExternalApis::Referral'
    belongs_to :hud_client, class_name: 'Hmis::Hud::Client'
  end
end
