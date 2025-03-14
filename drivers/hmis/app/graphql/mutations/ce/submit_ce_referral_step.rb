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
    argument :confirmed, Boolean, required: false

    field :step, Types::HmisSchema::CeReferralStep, null: true # nullable in case of errors
    field :referral, Types::HmisSchema::CeReferral, null: true # return the referral so the UI can respond appropriately if the referral's overall status has changed

    def resolve(referral_id:, step_id:, input:, confirmed: false)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      errors = HmisErrors::Errors.new

      unless confirmed
        # dependency injection style engine
        dry_run_engine = Hmis::WorkflowExecution::Engine.new(
          referral.workflow_instance,
          message_handler: Hmis::Ce::DryRunMessageHandler.new,
          stepper: Hmis::Ce::DryRunEngineStepper.new,
          assignment_handler: nil, # dry runner does not do any assignment
          audit_logger: nil, # or log audit events
        )

        step = dry_run_engine.active_steps.find(step_id)

        errors.push(*validate(step, input))
        return { errors: errors } if errors.any? # return early - if there are validation errors, they may cause the dry run to fail

        dry_run_engine.complete_step!(step, user: current_user, submitted_values: input)

        # todo @martha - this isn't flexible enough, it needs to be configurable which types of messages require a warning.
        # example with admin denials - we don't need to warn the admin that they are moving the referral to 'rejected,' we need to warn the non-admin that they are sending the referral to an admin for review

        if dry_run_engine.message_handler.collected_messages.map(&:type).include?('reject_referral')
          errors.add(:base, :information, message: 'This will decline the referral', severity: :warning)
          return { errors: errors }
        end
      end

      referral.opportunity.with_lock do
        engine = referral.workflow_engine
        step = engine.active_steps.find(step_id)

        errors.push(*validate(step, input))
        return { errors: errors } if errors.any?

        engine.complete_step!(step, user: current_user, submitted_values: input)
      end

      {
        step: step,
        referral: referral.reload,
      }
    end

    def validate(step, submitted_values)
      definition = step.node.form_definition
      return unless definition && submitted_values

      definition.validate_form_values(submitted_values)
    end
  end
end
