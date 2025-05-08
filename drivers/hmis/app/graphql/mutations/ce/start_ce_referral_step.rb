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
      project = referral.opportunity.project
      step = nil
      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)

        project_perm = current_permission?(permission: :can_perform_any_referral_tasks, entity: project)
        assignment_perm = current_permission?(permission: :can_perform_own_referral_tasks, entity: project) && step.assignments.any? { |assignment| assignment.user == current_user }
        access_denied! unless project_perm || assignment_perm

        engine.start_step!(step, user: current_user)
      end

      {
        step: step.reload,
      }
    end
  end
end
