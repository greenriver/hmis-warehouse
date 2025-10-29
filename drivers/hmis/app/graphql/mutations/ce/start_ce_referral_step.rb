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
    field :step, Types::HmisSchema::CeReferralStep, null: true # nullable in case of validation errors

    def resolve(referral_id:, step_id:)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      step = nil
      errors = HmisErrors::Errors.new

      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.instance.steps.find_by(id: step_id)
        access_denied! unless step.present?
        access_denied! unless policy_for(referral, policy_type: :ce_referral).can_perform?(step: step)

        errors.add :step_id, :invalid, full_message: HmisErrors::ApiError::STALE_OBJECT_ERROR unless step.open?
        return { errors: errors } if errors.any?

        # Start step. Skip if step is in progress, which indicates that someone has already started this step.
        engine.start_step!(step, user: current_user) unless step.in_progress?
      end

      {
        step: step.reload,
      }
    end
  end
end
