###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CreateDirectCeReferral < CleanBaseMutation
    argument :target_unit_group_id, ID, required: true
    argument :source_enrollment_id, ID, required: true
    argument :values_by_link_id, Types::JsonObject, required: true
    argument :values_by_field_name, Types::JsonObject, required: true
    argument :form_definition_id, ID, required: true # The form that was used to submit the step
    argument :confirmed, Boolean, required: false

    field :referral, Types::HmisSchema::CeReferral, null: true # nullable in case of validation errors

    # todo @martha - generate spec for this
    def resolve(target_unit_group_id:, source_enrollment_id:, values_by_link_id:, values_by_field_name:, form_definition_id:, confirmed: false)
      raise unless Hmis::Ce.configuration.enabled?

      source_enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find(source_enrollment_id)
      access_denied! unless current_permission?(permission: :can_manage_outgoing_referrals, entity: source_enrollment.project)

      unit_group = Hmis::UnitGroup.find(target_unit_group_id)
      target_project = unit_group.project # does not need to be viewable by current user
      access_denied! unless target_project.accepts_direct_ce_referrals_from?(source_enrollment.project)

      errors = HmisErrors::Errors.new

      unit = unit_group.units.preload(:latest_opportunity).accepting_ce_referrals.first

      unless unit.present?
        errors.add(:base, :invalid, full_message: unavailable_error(unit_group, target_project))
        return { errors: errors }
      end

      form_definition = Hmis::Form::Definition.find(form_definition_id)
      raise unless form_definition.valid_status_for_submit?

      opportunity = unit.latest_opportunity # should be present thanks to accepting_ce_referrals scope
      referral = nil

      opportunity.with_lock do # todo @martha - learn about with_lock vs. transaction. does this happen inside of a transaction? creating the referral but not the step shouldn't happen
        unless opportunity.open? # check inside lock for race condition
          errors.add(:base, :invalid, full_message: unavailable_error(unit_group, target_project))
          return { errors: errors }
        end

        instance = opportunity.workflow_template.instances.create!
        referral = opportunity.referrals.create!(
          workflow_instance: instance,
          referred_by: current_user,
          client: source_enrollment.client,
          source_enrollment: source_enrollment,
          referral_origin: 'project',
        )

        engine = referral.workflow_engine
        engine.start_workflow!(user: current_user)

        # there should be only one active step if the workflow is correctly configured
        step = engine.active_steps.find { |s| s.node.delegated_handoff? }
        raise unless step.present?

        # Intentionally don't check current user's permissions to complete this step.
        # User doesn't need permission in the target project, if they have can_manage_outgoing_referrals in the source project
        step.form_definition = form_definition

        validations = engine.validate_step(step, submitted_values: values_by_link_id)
        errors.push(*validations)
        errors.drop_warnings! if confirmed
        errors.deduplicate!
        return { errors: errors } if errors.any?

        engine.start_step!(step, user: current_user)

        # Process submitted values into CustomDataElements
        step.build_form_processor(definition: step.form_definition, values: values_by_link_id, hud_values: values_by_field_name)
        step.form_processor.run!(user: current_user)

        engine.complete_step!(step, user: current_user, submitted_values: values_by_link_id)
      end

      { referral: referral }
    end

    private

    def unavailable_error(unit_group, target_project)
      "Unit group #{unit_group.name} at project #{target_project.project_name} no longer has availability."
    end
  end
end
