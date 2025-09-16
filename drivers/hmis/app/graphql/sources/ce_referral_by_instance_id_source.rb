###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  class CeReferralByInstanceIdSource < GraphQL::Dataloader::Source
    # Custom GraphQL data source to resolve referrals by instance ID.
    # (Useful for avoiding n+1 issues when batch-loading steps,
    # which do not have a direct relationship to CE Referrals, so can't use load_ar_association.)

    # input: list of `instance_ids` whose Referrals we want to load
    # output: list of `Hmis::Ce::Referral`s, one for each instance_id passed in, in the same order as the input
    def fetch(instance_ids)
      # Batch load all referrals for the given instance IDs
      referrals_by_instance_id = Hmis::Ce::Referral.
        where(workflow_instance_id: instance_ids).
        group_by(&:workflow_instance_id). # Group the referrals by instance ID
        transform_values(&:sole) # There should be exactly 1 referral per instance ID

      # Return a list of referrals, one for each of the instance IDs, in the same order as the inputs
      instance_ids.map { |id| referrals_by_instance_id[id] }
    end
  end
end
