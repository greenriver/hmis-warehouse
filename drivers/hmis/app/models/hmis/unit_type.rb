###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class UnitType < HmisBase
    has_many :external_referral_requests, class_name: 'HmisExternalApis::ReferralRequest', dependent: :restrict_with_exception
  end
end
