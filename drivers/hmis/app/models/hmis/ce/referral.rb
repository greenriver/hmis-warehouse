###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A referral of an individual client to an opportunity
module Hmis::Ce
  class Referral < GrdaWarehouseBase
    include SimpleStateMachine

    has_paper_trail

    belongs_to :opportunity, class_name: 'Hmis::Ce::Opportunity'
    belongs_to :workflow_instance, class_name: 'Hmis::WorkflowExecution::Instance'
    has_one :workflow_template, class_name: 'Hmis::WorkflowDefinition::Template', through: :workflow_instance, source: :template
    has_many :notes, class_name: 'Hmis::Ce::ReferralNote'
    has_many :participants, class_name: 'Hmis::Ce::ReferralParticipant', dependent: :destroy
    belongs_to :client, class_name: 'Hmis::Hud::Client'
    belongs_to :referred_by, class_name: 'Hmis::User'
    belongs_to :target_enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    has_one :target_project, class_name: 'Hmis::Hud::Project', through: :opportunity, source: :project
    has_many :swimlanes, through: :workflow_instance, class_name: 'Hmis::WorkflowDefinition::Swimlane'
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance

    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance, source: :steps
    has_many :current_steps, -> { preload(:node) }, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance, source: :open_steps

    scope :viewable_by, ->(user) do
      # What makes a referral viewable by a user?
      # - If they have can_view_referrals at the target project, OR
      # - If they have can_view_own_referrals, AND are assigned a step in the referral.

      base_scope = joins(:target_project)

      # Referrals that the user can view because they have can_view_referrals in the target project
      access_through_project = base_scope.
        merge(Hmis::Hud::Project.viewable_by(user).with_access(user, :can_view_referrals))

      # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals.
      # Referral only becomes viewable once the assigned step becomes available.
      # Note that the user does *not* need can_view_project in this case
      own_referral_ids = base_scope.with_available_step_assigned_to(user).
        merge(Hmis::Hud::Project.with_access(user, :can_view_own_referrals)).
        pluck(:id) # pluck to avoid duplicates in resulting scope (from the step join)

      access_through_project.or(base_scope.where(id: own_referral_ids))
    end

    # Referrals that have a step assigned to the specified user. Excludes referrals if the assigned step(s) are unavailable.
    scope :with_available_step_assigned_to, ->(user) do
      assigned_step_ids = user.workflow_step_assignments.pluck(:step_id)
      joins(:steps).merge(Hmis::WorkflowExecution::Step.where(id: assigned_step_ids).excluding_unavailable)
    end

    scope :active, -> { where.not(status: ['accepted', 'rejected']) }
    scope :active_or_accepted, -> { where.not(status: 'rejected') }

    # Default sort for displaying referrals. Floats 'in_progress' and 'initialized' to the top,
    # then sorts by updated_at descending.
    # This is used in the frontend to display referrals in a consistent order.
    scope :order_by_status, -> do
      conditions = [
        [arel_table[:status].eq('initialized'), 1],
        [arel_table[:status].eq('in_progress'), 1],
        [arel_table[:status].eq('accepted'), 2],
        [arel_table[:status].eq('rejected'), 2],
      ]
      order(acase(conditions, elsewise: 3), updated_at: :desc, id: :asc)
    end

    validates :workflow_instance, uniqueness: true
    validate :unique_referral_per_opportunity
    validate :ce_template

    state_machine_config column: 'status' do
      state :initialized, initial: true
      state :in_progress
      state :accepted
      state :rejected

      event :start do
        transitions from: :initialized, to: :in_progress
      end
      event :accept do
        transitions from: :in_progress, to: :accepted
      end
      event :reject do
        transitions from: :in_progress, to: :rejected
      end
      # event :stall do
      #   transitions from: :active, to: :stalled
      # end
    end

    def workflow_engine
      @workflow_engine ||= Hmis::WorkflowExecution::Engine.new(
        workflow_instance,
        message_handler: Hmis::Ce::ReferralMessageHandler.new(self),
        assignment_handler: Hmis::Ce::ReferralTaskAssignmentHandler.new(self),
      )
    end

    def active?
      !accepted? && !rejected?
    end

    def self.apply_filters(input)
      Hmis::Filter::CeReferralFilter.new(input).filter_scope(self)
    end

    private

    def unique_referral_per_opportunity
      # Opportunities are single-use, so there should only be one in-progress or accepted referral,
      # but there could be many rejected referrals.
      return if status.to_sym == :rejected

      conflicting_referral_exists = Hmis::Ce::Referral.where.not(status: 'rejected').
        where(opportunity_id: opportunity_id).
        where.not(id: id).
        exists?
      return unless conflicting_referral_exists

      errors.add(:opportunity, 'can only have one active or accepted referral')
    end

    def ce_template
      return if workflow_instance.template.template_type == 'ce_referral'

      errors.add(:workflow_instance, 'must be a CE template')
    end
  end
end
