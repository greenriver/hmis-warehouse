###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis
  module Hmis
    module Hud
      module ProjectExtension
        extend ActiveSupport::Concern

        included do
          # Legacy External ReferralRequests sent to LINK from this project
          has_many :external_referral_requests, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', dependent: :destroy
          # Legacy External "incoming" ReferralPostings for this project.
          # They may be incoming from another HMIS project, or incoming from the external LINK system.
          has_many :external_referral_postings, class_name: 'HmisExternalApis::AcHmis::ReferralPosting', dependent: :destroy
        end
      end
    end
  end
end
