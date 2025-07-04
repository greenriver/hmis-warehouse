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
      access_denied! unless current_user.permissions_for?(referral.target_project, :can_perform_any_referral_tasks, :can_perform_own_referral_tasks, mode: :any)

      # If step specified, ensure the user has permission to perform actions on that step
      if step_id
        step = referral.steps.find(step_id) # ensure step_id is valid
        access_denied! unless current_user.can_perform_referral_step?(step)
      end

      referral.notes.create!(note: note, user: current_user, wfe_step_id: step_id)

      # Reload the referral to include the new note in response
      { referral: referral.reload }
    end
  end
end
