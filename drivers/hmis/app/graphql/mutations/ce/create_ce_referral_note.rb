###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CreateCeReferralNote < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :note, String, required: true
    argument :step_id, ID, required: false, description: 'Optional step ID to associate the note with a specific step in the referral workflow'
    field :referral, Types::HmisSchema::CeReferral, null: false

    def resolve(referral_id:, note:, step_id: nil)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)

      # Load the step (if provided) and authorize
      step = referral.steps.find(step_id) if step_id
      referral_policy = policy_for(referral, policy_type: :ce_referral)
      access_denied! unless referral_policy.can_create_note?(step: step)

      referral.notes.create!(note: note, user: current_user, wfe_step_id: step_id)

      # Reload the referral to include the new note in response
      { referral: referral.reload }
    end
  end
end
