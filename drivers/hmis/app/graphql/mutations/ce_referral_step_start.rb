#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CeReferralStepStart < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    field :step, Types::HmisSchema::CeReferralStep, null: false

    def resolve(referral_id:, step_id:)
      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      engine = referral.workflow_engine
      step = engine.steps.active.find(step_id)
      engine.start_step!(step, user: current_user)
      { step: step }
    end
  end
end
