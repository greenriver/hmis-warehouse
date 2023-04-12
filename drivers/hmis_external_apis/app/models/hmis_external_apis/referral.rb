###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # A request for a service for a household. The service is not necessarily housing.
  class Referral < HmisExternalApisBase
    self.table_name = 'hmis_external_referrals'
    has_many :referral_clients, class_name: 'HmisExternalApis::ReferralClient', dependent: :destroy
    has_many :referral_postings, class_name: 'HmisExternalApis::ReferralPosting', dependent: :destroy
  end
end
