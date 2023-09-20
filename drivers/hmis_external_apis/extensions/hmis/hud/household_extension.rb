###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module HouseholdExtension
        extend ActiveSupport::Concern

        included do
          has_many :external_referral_postings, **hmis_relation(:HouseholdID), class_name: 'HmisExternalApis::AcHmis::ReferralPosting', inverse_of: :household
        end
      end
    end
  end
end
