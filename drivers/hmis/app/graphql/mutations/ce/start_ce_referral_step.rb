###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::StartCeReferralStep < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    field :step, Types::HmisSchema::CeReferralStep, null: false

    def resolve(referral_id:, step_id:)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      step = nil
      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)

        participants = referral.participants_for_swimlane(step.swimlane.id)
        raise 'Cannot start a referral step with no participants' unless participants.any?

        # TODO(#7395): permission

        step.assignments.find_or_create_by!(user: current_user)
        engine.start_step!(step, user: current_user)
      end

      context[:referral] = referral
      { step: step }
    end
  end
end
