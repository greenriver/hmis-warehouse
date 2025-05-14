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
    has_many :notes, class_name: 'Hmis::Ce::ReferralNote'
    has_many :participants, class_name: 'Hmis::Ce::ReferralParticipant'
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

      # Start with base scope that does all necessary joins, for structural compatibility when we `or` the scopes later
      base_scope = joins(:target_project).left_outer_joins(:steps).left_outer_joins(steps: :assignments)

      # todo @martha - same question here about project viewable access
      # Projects in which the user can_view_referrals
      access_through_project = base_scope.
        merge(Hmis::Hud::Project.with_access(user, :can_view_referrals))

      # Referrals that have a step assigned to this user, in projects in which the user can_view_own_referrals
      own_referrals = base_scope.
        merge(Hmis::Hud::Project.with_access(user, :can_view_own_referrals)).
        merge(
          Hmis::WorkflowExecution::Step.
            where(Hmis::WorkflowExecution::StepAssignment.arel_table[:user_id].eq(user.id)).
            where.not(status: 'unavailable'),
        )

      access_through_project.or(own_referrals).distinct
    end

    scope :active, -> { where.not(status: ['accepted', 'rejected']) }
    scope :active_or_accepted, -> { where.not(status: 'rejected') }

    validates :workflow_instance, uniqueness: true
    validate :unique_referral_per_opportunity

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

    # This is a helper on Referral, rather than on Step, because we want to keep Workflow Execution code encapsulated away from CE code
    def user_can_perform_task?(user:, step:)
      raise unless step.instance == workflow_instance

      permission_from_project = user.can_perform_any_referral_tasks_for?(target_project)
      permission_from_assignment = user.can_perform_own_referral_tasks_for?(target_project) && step.assignments.any? { |assignment| assignment.user == user }

      permission_from_project || permission_from_assignment
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
  end
end
