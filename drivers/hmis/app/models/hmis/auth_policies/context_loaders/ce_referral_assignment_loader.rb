###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require 'memery'

module Hmis::AuthPolicies::ContextLoaders
  class CeReferralAssignmentLoader
    include Memery

    def initialize(user)
      @user = user
    end

    memoize def assigned_referral_instance_ids
      (assigned_referral_steps.pluck(:instance_id) + workflow_instance_ids_with_completed_swimlane_steps).to_set
    end

    memoize def assigned_referral_step_ids
      assigned_referral_steps.pluck(:id).to_set
    end

    private

    # Returns workflow instance IDs where there are completed steps assigned to
    # swimlanes that the current user participates in.
    #
    # This allows users to see referrals they're involved with through swimlane
    # participation, even if no steps are currently directly assigned to them.
    #
    # Note: this logic is mirrored by `Referral#with_completed_steps_assigned_to_swimlane`
    #
    # @return [Array<Integer>] Array of workflow instance IDs
    # @example
    #   # Referral has a task assigned to "Project Staff" swimlane
    #   # User X completes the project staff task
    #   # Later, User Y is added as a participant to the "Project Staff" swimlane for the referral
    #   # Because of this method, User Y is now granted access to view this referral as their "own" referral
    def workflow_instance_ids_with_completed_swimlane_steps
      # Get all referral participants for the user with their referral and swimlane info
      participants = @user.ce_referral_participants.
        joins(:referral, :swimlane).
        select(:referral_id, :swimlane_id, 'ce_referrals.workflow_instance_id').
        distinct

      # Get all unique workflow instance IDs
      instance_ids = participants.pluck(:workflow_instance_id).compact.uniq
      return [] if instance_ids.empty?

      # Preload all completed steps for all instances in one query, with their assignments and user_tasks
      all_steps = Hmis::WorkflowExecution::Step.
        where(instance_id: instance_ids).
        completed.
        joins(:user_task).
        preload(:user_task, :assignments).
        group_by(&:instance_id)

      # Preload all referrals for these instances in one query
      Hmis::Ce::Referral.
        where(workflow_instance_id: instance_ids).
        index_by(&:workflow_instance_id)

      # Filter instances that have completed steps assigned to the user's swimlanes
      assigned_instance_ids = []

      participants.each do |participant|
        instance_id = participant.workflow_instance_id
        # Check if this instance has completed steps for this swimlane
        completed_swimlane_steps = all_steps[instance_id]&.select { |step| step.user_task&.swimlane_id == participant.swimlane_id }
        assigned_instance_ids << instance_id if completed_swimlane_steps&.any?
      end

      assigned_instance_ids
    end

    def assigned_referral_steps
      Hmis::WorkflowExecution::Step.
        excluding_unavailable.
        joins(:user_task, :assignments).
        where(assignments: { user_id: @user.id })
    end
  end
end
