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
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    belongs_to :status_updated_by, class_name: 'Hmis::User', optional: true
    belongs_to :status_note_updated_by, class_name: 'Hmis::User', optional: true

    # Enrollment(s) are only present if this referral was accepted
    has_many :enrollments, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Enrollment')
    has_one :hoh_enrollment, -> { where(relationship_to_hoh: 1) }, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Enrollment')
    has_one :household, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Household')

    scope :viewable_by, ->(_user) { raise } # this scope is replaced by ::Hmis::Hud::Concerns::ProjectRelated
    include ::Hmis::Hud::Concerns::ProjectRelated

    alias_attribute :household_id, :HouseholdID
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

    VALID_LOCAL_STATUSES = ['assigned_status', 'accepted_pending_status', 'denied_pending_status'].freeze
    VALID_LOCAL_STATUS_IDS = statuses.values_at(*VALID_LOCAL_STATUSES).freeze

    validates :status, presence: true
    validates :status, inclusion: { in: VALID_LOCAL_STATUSES }, on: :hmis_user_action
    validates :status_note, length: { maximum: 4_000 }, on: :hmis_user_action
    validates :denial_reason, presence: true, if: :denied_pending_status?, on: :hmis_user_action
    validates :denial_note, length: { maximum: 2_000 }, on: :hmis_user_action
    validates :denial_note, presence: true, if: :denied_status?, on: :hmis_user_action
    validates :referral_result, presence: true, if: :denied_status?, on: :hmis_user_action

    before_create do
      self.status_updated_at ||= created_at
    end

    INACTIVE_STATUSES = [:closed_status, :accepted_by_other_program_status, :denied_status].freeze
    scope :active, -> { where.not(status: INACTIVE_STATUSES) }

    # referral came from LINK
    def from_link?
      identifier.present?
    end

    attr_accessor :current_user
    before_update :track_status_changes
    def track_status_changes
      user = current_user || Hmis::User.system_user
      if status_note_changed?
        self.status_note_updated_at = Time.current unless status_note_updated_at_changed?
        self.status_note_updated_by_id = user.id unless status_note_updated_by_id_changed?
      end
      if status_changed? # rubocop:disable Style/GuardClause
        self.status_updated_at = Time.current unless status_updated_at_changed?
        self.status_updated_by_id = user.id unless status_updated_by_id_changed?
      end
    end
  end
end
