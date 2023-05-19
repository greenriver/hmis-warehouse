###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # A request for a service for a household. The service is not necessarily housing.
  class Referral < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referrals'
    has_many :household_members, class_name: 'HmisExternalApis::AcHmis::ReferralHouseholdMember', dependent: :destroy
    has_many :postings, class_name: 'HmisExternalApis::AcHmis::ReferralPosting', dependent: :destroy
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true

    def postings_inactive?
      postings.all? do |posting|
        posting.closed_status? || posting.denied_pending_status?
      end
    end
  end
end
