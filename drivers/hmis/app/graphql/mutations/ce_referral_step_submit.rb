###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class CeReferralStepSubmit < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :step_id, ID, required: true
    argument :input, Types::JsonObject, required: true
    argument :confirmed, Boolean, required: false

    field :step, Types::HmisSchema::CeReferralStep, null: true # nullable in case of errors
    field :referral, Types::HmisSchema::CeReferral, null: true # return the referral so the UI can respond appropriately if the referral's overall status has changed

    def resolve(referral_id:, step_id:, input:, confirmed: false)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      errors = HmisErrors::Errors.new

      unless confirmed
        dry_run_engine = Hmis::WorkflowExecution::Engine.new(
          referral.workflow_instance,
          message_handler: Hmis::Ce::DryRunMessageHandler.new,
          assignment_handler: nil, # dry runner does not do any assignment
          # it feels weird to BOTH create the "dry run engine" AND call the "dry run" method.
          # it feels like what you want is just to either
          # - initialize the engine and then call it, and then if there are errors return them, or
          # - get the same (regular) engine, and then call its dry run function, which handles everything internally.
          dry_run: true,
        )

        step = dry_run_engine.active_steps.find(step_id)
        dry_run_engine.dry_run_step(step, submitted_values: input)

        if dry_run_engine.message_handler.collected_messages.map(&:type).include?('reject_referral')
          errors.add(:root, message: 'This will decline the referral', severity: :warning)
          return { errors: errors }
        end
      end

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
