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

    def initialize(data_source)
      @data_source = data_source

      # Validate required forms exist
      missing = FORMS.values - Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?
    end

    def ensure_decline_reasons
      [
        { "code": 'ineligible', "label": 'Does not meet eligibility criteria' },
        { "code": 'enrolled_declined_hmis_data_entry', "label": 'Enrolled, but declined HMIS data entry' },
        { "code": 'referral_sent_in_error', "label": 'Referral sent in error' },
        { "code": 'hmis_user_error_client_enrolled_without_accepting_referral', "label": 'HMIS User Error - Client enrolled without accepting referral' },
        { "code": 'not_experiencing_homelessness', "label": 'No longer experiencing homelessness' },
        { "code": 'enrolled_in_equivalent_service', "label": 'Enrolled in equivalent service with another provider' },
        { "code": 'unable_to_locate_client', "label": 'Unable to contact/locate' },
        { "code": 'client_not_interested', "label": 'No longer interested in the program' },
        { "code": 'other', "label": 'Other (detail in notes section)' },
      ].each do |option|
        Hmis::Ce::ReferralDeclineReason.find_or_create_by!(
          key: option[:code],
          data_source: @data_source,
        ) do |reason|
          reason.name = option[:label]
        end
      end
    end

    # These 3 `build_` methods hard-code their version number, and are intended to be idempotent on that version number.
    # This enables iterating on a template until it is ready to be published.
    # See README_FOR_PH_CE_WORKFLOWS.md for more details.
    def build_benefits_referral_workflow
      find_or_create_direct_referral_draft_template(
        identifier: 'benefits_referral',
        name: 'Benefits Referral',
        outgoing_step_form_identifier: FORMS.fetch(:benefits_referral),
        outgoing_step_name: 'Benefits Referral Details',
        version: 1,
      )
    end

    def build_shelter_referral_workflow
      find_or_create_direct_referral_draft_template(
        identifier: 'shelter_referral',
        name: 'Shelter Referral',
        outgoing_step_form_identifier: FORMS.fetch(:shelter_referral),
        outgoing_step_name: 'Shelter Referral Details',
        version: 1,
      )
    end

    def build_outreach_referral_workflow
      find_or_create_direct_referral_draft_template(
        identifier: 'outreach_referral',
        name: 'Outreach Referral',
        outgoing_step_form_identifier: FORMS.fetch(:outreach_referral),
        outgoing_step_name: 'Outreach Referral Details',
        version: 1,
      )
    end

    def find_or_create_direct_referral_draft_template(identifier:, name:, outgoing_step_form_identifier:, outgoing_step_name:, version: 0)
      template = CeWorkflows::Shared::CeBuilderUtils.find_or_create_draft_template(
        identifier: identifier,
        name: name,
        data_source: @data_source,
        version: version,
      )

      provider_swimlane = template.swimlanes.find_or_create_by!(name: 'Provider')
      referrer_swimlane = template.swimlanes.find_or_create_by!(name: 'Referrer')

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)

      # Step 1: Send referral
      send_referral_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: outgoing_step_name,
        form_definition_identifier: outgoing_step_form_identifier,
        template: template,
      )
      # Swimlane is mostly irrelevant since this is just for direct referrals and is completed by the sending project.
      # But, it's less confusing to use a different swimlane to avoid confusion in the UI, especially with default contacts.
      send_referral_task.swimlane = referrer_swimlane
      send_referral_task.save!

      # Step 2: Provider decision (accept/deny with note)
      provider_decision_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
      )
      provider_decision_task.trigger_config = [
        {
          event: 'complete_step',
          message: 'set_referral_decline_reason',
        },
      ]
      provider_decision_task.save!

      # Script task: create enrollment if referral is accepted
      create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.find_or_initialize_by(
        name: 'Create Enrollment',
        template: template,
      )
      create_enrollment_task.trigger_config = [
        {
          event: 'complete_step',
          message: 'create_enrollment',
        },
      ]
      create_enrollment_task.save!

      # Exclusive gateway for decision routing
      decision_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'provider_decision')

      # Wire up flow
      start_event.connect_to!(send_referral_task) unless start_event.outflows.exists?(target_node: send_referral_task)
      send_referral_task.connect_to!(provider_decision_task) unless send_referral_task.outflows.exists?(target_node: provider_decision_task)
      provider_decision_task.connect_to!(decision_gateway) unless provider_decision_task.outflows.exists?(target_node: decision_gateway)
      decision_gateway.connect_to!(create_enrollment_task, condition: 'decision = 1') unless decision_gateway.outflows.exists?(target_node: create_enrollment_task)
      create_enrollment_task.connect_to!(accept_event) unless create_enrollment_task.outflows.exists?(target_node: accept_event)
      decision_gateway.connect_to!(decline_event) unless decision_gateway.outflows.exists?(target_node: decline_event)

      template.validate!
      template
    end
  end
end
