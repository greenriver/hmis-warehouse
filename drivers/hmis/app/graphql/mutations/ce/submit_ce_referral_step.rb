###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::SubmitCeReferralStep < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    argument :input, Types::JsonObject, required: true
    argument :form_definition_id, ID, required: true # The form that was used to submit the step
    argument :confirmed, Boolean, required: false

    field :step, Types::HmisSchema::CeReferralStep, null: true # nullable in case of errors
    field :referral, Types::HmisSchema::CeReferral, null: true # return the referral so the UI can respond appropriately if the referral's overall status has changed

    def resolve(referral_id:, step_id:, form_definition_id:, input:, **_rest) # add 'confirmed' here later. For now, we ignore it
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      step = nil
      errors = HmisErrors::Errors.new
      form_definition = Hmis::Form::Definition.find(form_definition_id)
      raise unless form_definition.valid_status_for_submit?

      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)
        step.form_definition = form_definition
        access_denied! unless policy_for(referral, policy_class: Hmis::AuthPolicies::CeReferralPolicy).can_perform?(step: step)

        validations = engine.validate_step(step, submitted_values: input)
        errors.push(*validations)
        return { errors: errors } if errors.any?

        engine.complete_step!(step, user: current_user, submitted_values: input)
      end

      {
        step: step.reload,
        referral: referral.reload,
      }
    end
  end
end
