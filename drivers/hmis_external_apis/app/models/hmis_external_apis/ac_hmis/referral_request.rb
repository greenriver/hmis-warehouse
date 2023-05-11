###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # An advertisement of housing vacancy
  class ReferralRequest < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referral_requests'
    scope :viewable_by, ->(_user) { self } # this scope is replaced by ::Hmis::Hud::Concerns::ProjectRelated
    include ::Hmis::Hud::Concerns::ProjectRelated

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :unit_type, class_name: 'Hmis::UnitType'
    belongs_to :requested_by, class_name: 'Hmis::User'
    belongs_to :voided_by, class_name: 'Hmis::User', optional: true
    has_many :external_referrals, class_name: 'HmisExternalApis::AcHmis::Referral', dependent: :restrict_with_exception

    # active postings are ones that have not yet been fulfilled (not referenced by a referral)
    scope :active, -> {
      where.not(id: HmisExternalApis::AcHmis::ReferralPosting.select(:referral_request_id))
    }
  end
end
