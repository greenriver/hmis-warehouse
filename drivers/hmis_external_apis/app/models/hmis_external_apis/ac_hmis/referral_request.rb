###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # An advertisement of housing vacancy
  class ReferralRequest < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referral_requests'
    scope :viewable_by, ->(_user) { raise } # this scope is replaced by ::Hmis::Hud::Concerns::ProjectRelated
    include ::Hmis::Hud::Concerns::ProjectRelated

    # needed for duck-typing in submit form mutation
    attr_accessor :data_source_id

    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :unit_type, class_name: 'Hmis::UnitType'
    belongs_to :requested_by, class_name: 'Hmis::User'
    belongs_to :voided_by, class_name: 'Hmis::User', optional: true
    # The referral posting that fulfills this request (if any)
    has_one :referral_posting, class_name: 'HmisExternalApis::AcHmis::ReferralPosting', required: false

    # active requests are ones that have not yet been fulfilled (not referenced by a referral)
    scope :active, -> { where(referral_posting: nil, voided_at: nil) }
  end
end
