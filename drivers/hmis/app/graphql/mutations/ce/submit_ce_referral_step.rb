###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class Ce::SubmitCeReferralStep < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    argument :input, Types::JsonObject, required: true
    field :step, Types::HmisSchema::CeReferralStep, null: false
    field :referral, Types::HmisSchema::CeReferral, null: false # return the referral so the UI can respond appropriately if the referral's overall status has changed

    def resolve(referral_id:, step_id:, input:)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      step = nil
      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)
        engine.complete_step!(step, user: current_user, submitted_values: input)
      end
      {
        step: step,
        referral: referral.reload,
      }
    end
  end
end
