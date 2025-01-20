#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CeReferralStepSubmit < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    argument :input, Types::JsonObject, required: true
    field :step, Types::HmisSchema::CeReferralStep, null: false

    def resolve(referral_id:, step_id:, input:)
      raise unless Hmis::Ce.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)
        engine.complete_step!(step, user: current_user, submitted_values: input)
      end
      { step: step }
    end
  end
end
