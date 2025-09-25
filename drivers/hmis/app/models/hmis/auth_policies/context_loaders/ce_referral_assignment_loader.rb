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
      (assigned_referral_steps.pluck(:instance_id) + referrals_with_completed_swimlane_steps.pluck(:workflow_instance_id)).to_set
    end

    memoize def assigned_referral_step_ids
      assigned_referral_steps.pluck(:id).to_set
    end

    # Clear memery cache when step assignments may have changed during a request (e.g., after completing a step in a mutation).
    def clear_cache!
      clear_memery_cache!
      self
    end

    private

    def assigned_referral_steps
      Hmis::WorkflowExecution::Step.
        excluding_unavailable.
        joins(:user_task, :assignments).
        where(assignments: { user_id: @user.id })
    end

    # Referrals where there are completed steps assigned to a swimlane that the current user participates in.
    #
    # This allows users to see referrals they're involved with through swimlane
    # participation, even if no steps are currently directly assigned to them.
    def referrals_with_completed_swimlane_steps
      referral_ids = Hmis::Ce::Referral.referral_ids_for_user_with_completed_swimlane_steps(@user)
      Hmis::Ce::Referral.where(id: referral_ids)
    end
  end
end
