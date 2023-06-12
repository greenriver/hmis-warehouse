###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # A proposed fulfillment of a referral request
  class ReferralPosting < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referral_postings'
    belongs_to :referral, class_name: 'HmisExternalApis::AcHmis::Referral'
    belongs_to :referral_request, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', optional: true
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :unit_type, class_name: 'Hmis::UnitType'

    belongs_to :status_updated_by, class_name: 'Hmis::User', optional: true
    belongs_to :status_note_updated_by, class_name: 'Hmis::User', optional: true

    scope :viewable_by, ->(_user) { raise } # this scope is replaced by ::Hmis::Hud::Concerns::ProjectRelated
    include ::Hmis::Hud::Concerns::ProjectRelated

    # https://docs.google.com/spreadsheets/d/12wRLTjNdcs7A_1lHwkLUoKz1YWYkfaQs/edit#gid=26094550
    enum(
      status: {
        assigned_status: 12,
        closed_status: 13,
        accepted_pending_status: 18,
        denied_pending_status: 19,
        accepted_status: 20,
        denied_status: 21,
        accepted_by_other_program_status: 22,
        not_selected_status: 23,
        void_status: 25,
        new_status: 55,
        assigned_to_other_program_status: 60,
        # closed: 65,
      },
      referral_result: ::HudUtility.hud_list_map_as_enumerable(:referral_result_map),
    )

    validates :status_note, length: { maximum: 4_000 }
    validates :denial_note, length: { maximum: 2_000 }

    before_create do
      self.status_updated_at ||= created_at
    end

    INACTIVE_STATUSES = [:closed_status, :accepted_by_other_program_status, :denied_status].freeze
    scope :active, -> { where.not(status: INACTIVE_STATUSES) }
  end
end
