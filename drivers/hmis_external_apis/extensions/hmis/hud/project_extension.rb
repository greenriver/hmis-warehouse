###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module ProjectExtension
        extend ActiveSupport::Concern

        included do
          has_many :external_referral_requests, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', dependent: :destroy
          has_many :external_referral_postings, class_name: 'HmisExternalApis::AcHmis::ReferralPosting', dependent: :destroy
        end
      end
    end
  end
end
