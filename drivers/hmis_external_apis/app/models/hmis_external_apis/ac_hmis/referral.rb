###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # A request for a service for a household. The service is not necessarily housing.
  class Referral < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referrals'
    has_paper_trail(
      meta: {
        enrollment_id: :enrollment_id,
        client_id: ->(r) { r&.client&.id },
        project_id: ->(r) { r&.project&.id },
      },
    )

    has_many :household_members, class_name: 'HmisExternalApis::AcHmis::ReferralHouseholdMember', dependent: :destroy
    has_many :postings, class_name: 'HmisExternalApis::AcHmis::ReferralPosting', dependent: :destroy
    # The enrollment_id col stores a reference to the enrollment that the referral came from, which only gets set for
    # referrals that are made within the HMIS. For LINK-originating referrals, it's always null.
    #
    # For LINK originating referrals the association to the enrollment is through the HouseholdID column on the
    # the referral posting. The reason for using household ids, rather than enrollment ids, is because the household
    # membership may change but it still needs to remain "linked" to the posting.
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    has_one :client, through: :enrollment
    has_one :project, through: :enrollment

    def postings_inactive?
      postings.all?(&:inactive?)
    end
  end
end
