###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # A proposed fulfillment of a referral request
  class ReferralPosting < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_referral_postings'
    include ::Hmis::Hud::Concerns::FormSubmittable
    belongs_to :referral, class_name: 'HmisExternalApis::AcHmis::Referral'
    belongs_to :referral_request, class_name: 'HmisExternalApis::AcHmis::ReferralRequest', optional: true
    belongs_to :project, class_name: 'Hmis::Hud::Project' # project that is receiving the referral
    belongs_to :unit_type, class_name: 'Hmis::UnitType', optional: true
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    belongs_to :status_updated_by, class_name: 'Hmis::User', optional: true
    belongs_to :status_note_updated_by, class_name: 'Hmis::User', optional: true

    # Enrollment(s) are only present if this referral was accepted
    has_many :enrollments, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Enrollment')
    has_one :hoh_enrollment, -> { where(relationship_to_hoh: 1) }, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Enrollment')
    # see note about enrollment / household_id on enrollment in the Referral class
    has_one :household, **Hmis::Hud::Base.hmis_relation(:HouseholdID, 'Household')

    scope :from_link, -> { where.not(identifier: nil) }

    # viewability is based on whether the user can see the project that is RECEIVING the referral. It does not check referral perms.
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
      referral_result: ::HudUtility2024.hud_list_map_as_enumerable(:referral_results),
    )

    # Referrals in Denied Pending status can either be move to Denied (denial accepted) or to Assigned (denial rejected)
    DENIAL_STATUSES = ['assigned_status', 'denied_status'].freeze
    # Referrals in Assigned status can either be move to Accepted Pending or Denied Pending
    ASSIGNED_STATUSES = ['assigned_status', 'accepted_pending_status', 'denied_pending_status'].freeze

    OLD_STATUS_TO_VALID_NEW_STATUS = {
      assigned_status: [
        'accepted_pending_status', # accepted into program (tentatively)
        'denied_pending_status', # denied from program (tentatively)
      ],
      accepted_pending_status: [
        'accepted_status', # fully accepted to program (hoh intake assessment submitted)
        'denied_pending_status', # changed mind or mistake, denied from program
      ],
      accepted_status: ['closed_status'], # hoh exited
      denied_pending_status: [
        'denied_status', # denial accepted
        'assigned_status', # denial rejected ("sent back")
      ],
      closed_status: ['accepted_status'], # exited enrollment was re-opened
    }.stringify_keys.freeze

    validates :status, presence: true

    with_options on: :hmis_user_action do
      validates :status, inclusion: { in: ASSIGNED_STATUSES }
      validate :validate_status_change
      validates :status_note, presence: true, length: { maximum: 4_000 }
      validates :denial_reason, presence: true, if: :denied_pending_status?
      validates :denial_note, length: { maximum: 2_000 }
    end

    with_options on: :hmis_admin_action do
      validates :status, inclusion: { in: DENIAL_STATUSES }
      validate :validate_status_change
      validates :referral_result, presence: true, if: :denied_status?
      validates :denial_reason, presence: true, if: :denied_pending_status?
      validates :denial_note, length: { maximum: 2_000 }
    end

    validate :validate_unit_availability, on: :form_submission, if: :new_record?

    before_create do
      self.status_updated_at ||= created_at
      self.status_updated_by ||= current_user if current_user
    end

    ACTIVE_STATUSES = [:assigned_status, :accepted_pending_status, :denied_pending_status].freeze
    scope :active, -> { where(status: ACTIVE_STATUSES) }

    SORT_OPTIONS = [:relevent_status, :oldest_to_newest].freeze
    def self.sort_by_option(option)
      raise NotImplementedError unless SORT_OPTIONS.include?(option)

      case option
      when :relevent_status
        order(
          arel_table[:status].eq('assigned_status').desc,
          arel_table[:status].eq('accepted_pending_status').desc,
          arel_table[:status].eq('denied_pending_status').desc,
          arel_table[:status].eq('accepted_status').desc,
          arel_table[:status].eq('denied_status').desc,
          created_at: :desc,
        )
      when :oldest_to_newest
        order(created_at: :asc)
      else
        scope
      end
    end

    private def validate_status_change
      return unless status_changed? && status.present? && status_was.present?

      expected_statuses = OLD_STATUS_TO_VALID_NEW_STATUS[status_was]
      return unless expected_statuses.present?

      errors.add(:status, :invalid, message: "is invalid. Expected one of: #{expected_statuses.map(&:humanize).join(', ')}") unless expected_statuses.include?(status)
    end

    private def validate_unit_availability
      return unless unit_type_id.present?

      errors.add(:unit_type_id, :invalid, message: 'is not available in the selected project') unless project.units.unoccupied_on.where(unit_type_id: unit_type_id).exists?
    end

    # referral came from LINK
    def from_link?
      identifier.present?
    end

    def inactive?
      closed_status? || denied_status?
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

    # If a household has been referred out from a project (e.g. the HMIS Coordinated Entry Project) and the referral has
    # been accepted or denied, and there are no active referrals for the household, exit the household.
    def exit_origin_household(user:)
      # don't auto-exit if referral is from link
      return if from_link?

      # for find the origin household through the enrollment
      referral_household = referral&.enrollment&.household
      return unless referral_household

      referral_postings = referral_household.
        enrollments.
        preload(:external_referrals).
        flat_map { |e| e.external_referrals.flat_map(&:postings) }.
        filter { |p| p.id != id } # filter out self
      return unless referral_postings.all?(&:inactive?)

      today = Date.current
      origin_household = from_link? ? household : referral.enrollment.household
      exits = origin_household.enrollments.open_excluding_wip.map do |other_enrollment|
        other_enrollment.build_exit(
          exit_date: today,
          personal_id: other_enrollment.personal_id,
          user: user,
          destination: 30, # no exit interview performed
        )
      end
      Hmis::Hud::Exit.import!(exits)
    end

    # Initialize a new ReferralPosting with a Referral and ReferralHouseholdMembers
    def self.new_with_referral(enrollment:, receiving_project:, user:)
      referral = HmisExternalApis::AcHmis::Referral.new(
        enrollment: enrollment,
        referral_date: Time.current,
        service_coordinator: user.name,
      )
      referral.household_members = enrollment.household_members.preload(:client).map do |member|
        HmisExternalApis::AcHmis::ReferralHouseholdMember.new(
          relationship_to_hoh: member.relationship_to_hoh,
          client_id: member.client.id,
        )
      end
      posting = referral.postings.build(
        status: 'assigned_status',
        project: receiving_project,
        data_source: enrollment.data_source,
      )
      posting.current_user = user # used by track_status_changes
      posting
    end
  end
end
