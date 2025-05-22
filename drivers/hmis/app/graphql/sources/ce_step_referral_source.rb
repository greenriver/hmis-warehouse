###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  class CeStepReferralSource < GraphQL::Dataloader::Source
    # Custom GraphQL Dataloader to resolve the relationship between steps and referrals.
    # Steps live under WorkflowExecution so do not have a direct relationship to CE Referrals.
    # Since we can't use `load_ar_association`, this loader helps avoid n+1 issues.

    def fetch(steps)
      # Batch load referrals for the steps provided, and group them by workflow instance IDs
      referrals_by_instance_id = Hmis::Ce::Referral.
        where(workflow_instance_id: steps.map(&:instance_id)).
        group_by(&:workflow_instance_id).
        transform_values { |refs| refs.max_by(&:created_at) } # should be exactly 1 referral per instance ID

      # In the same order as the input steps, return a list of referrals associated with each step's instance ID
      steps.map { |step| referrals_by_instance_id[step.instance_id] }
    end
  end
end
