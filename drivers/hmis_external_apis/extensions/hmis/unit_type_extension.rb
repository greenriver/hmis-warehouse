###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module UnitTypeExtension
      extend ActiveSupport::Concern
      include ExternallyIdentifiedMixin

      included do
        has_many :external_referral_requests, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', dependent: :restrict_with_exception
        # has_many :external_referral_postings, class_name: ' HmisExternalApis::AcHmis::ReferralPosting', dependent: :restrict_with_exception
      end

      class_methods do
        def order_by_created_at(dir = :asc)
          order(created_at: dir)
        end
      end
    end
  end
end
