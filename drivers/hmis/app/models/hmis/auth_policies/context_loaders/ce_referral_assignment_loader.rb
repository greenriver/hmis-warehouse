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
      assigned_referral_steps.pluck(:instance_id).to_set
    end

    memoize def assigned_referral_step_ids
      assigned_referral_steps.pluck(:id).to_set
    end

    private

    def assigned_referral_steps
      Hmis::WorkflowExecution::Step.
        excluding_unavailable.
        joins(:user_task, :assignments).
        where(assignments: { user_id: @user.id })
    end
  end
end
