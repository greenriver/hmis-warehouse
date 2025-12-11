###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Utility for building CE workflow definitions specific to the PH installation.
module CeWorkflows::Ph
  class WorkflowBuilder
    FORMS = {
      benefits_referral: 'ce_benefits_referral',
      shelter_referral: 'ce_shelter_referral',
      outreach_referral: 'ce_outreach_referral',
      provider_decision: 'direct_referral_workflow_provider_decision',
    }.freeze

    def initialize(data_source, unsafe_run_in_production: false)
      @data_source = data_source
      @unsafe_run_in_production = unsafe_run_in_production

      # Validate required forms exist
      missing = FORMS.values - Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?

      raise 'This class destroys data and should not be run in production' if Rails.env.production? && !@unsafe_run_in_production
    end

    def build_benefits_referral_workflow
      build_direct_referral_workflow(
        identifier: 'benefits_referral',
        name: 'Benefits Referral',
        outgoing_step_form_identifier: FORMS.fetch(:benefits_referral),
        outgoing_step_name: 'Benefits Referral Details',
      )
    end

    def build_shelter_referral_workflow
      build_direct_referral_workflow(
        identifier: 'shelter_referral',
        name: 'Shelter Referral',
        outgoing_step_form_identifier: FORMS.fetch(:shelter_referral),
        outgoing_step_name: 'Shelter Referral Details',
      )
    end

    def build_outreach_referral_workflow
      build_direct_referral_workflow(
        identifier: 'outreach_referral',
        name: 'Outreach Referral',
        outgoing_step_form_identifier: FORMS.fetch(:outreach_referral),
        outgoing_step_name: 'Outreach Referral Details',
      )
    end

    def build_direct_referral_workflow(identifier:, name:, outgoing_step_form_identifier:, outgoing_step_name:)
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier) unless @unsafe_run_in_production

      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, name, @data_source)

      provider_swimlane = template.swimlanes.create!(name: 'Provider')

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.create_accept_event(template)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.create_decline_event(template)

      # Step 1: Send referral
      send_referral_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: outgoing_step_name,
        form_definition_identifier: outgoing_step_form_identifier,
        template: template,
        swimlane: provider_swimlane, # Swimlane is irrelevant since this is just for direct referrals and is completed by the sending project
      )

      # Step 2: Provider decision (accept/deny with note)
      provider_decision_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
      )

      # Script task: create enrollment if referral is accepted
      create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create Enrollment',
        template: template,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_enrollment',
          },
        ],
      )

      # Exclusive gateway for decision routing
      decision_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'provider_decision')

      # Wire up flow
      start_event.connect_to!(send_referral_task)
      send_referral_task.connect_to!(provider_decision_task)
      provider_decision_task.connect_to!(decision_gateway)
      decision_gateway.connect_to!(create_enrollment_task, condition: 'decision = 1')
      create_enrollment_task.connect_to!(accept_event)
      decision_gateway.connect_to!(decline_event)

      template.validate!
      template
    end
  end
end
