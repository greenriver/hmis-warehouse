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
      form_definition = Hmis::Form::Definition.find_by!(
        identifier: FORMS.fetch(:provider_decision),
        role: 'CE_REFERRAL_STEP',
      )
      decline_reason_item = form_definition.link_id_item_hash['decline_reason']

      CeWorkflows::Shared::CeBuilderUtils.ensure_decline_reasons_from_form_item(decline_reason_item, @data_source)
    end

    def build_benefits_referral_workflow
      build_direct_referral_workflow(
        identifier: 'benefits_referral',
        name: 'Benefits Referral',
        outgoing_step_form_identifier: FORMS.fetch(:benefits_referral),
        outgoing_step_name: 'Benefits Referral Details',
        version: 1,
      )
    end

    def build_shelter_referral_workflow
      build_direct_referral_workflow(
        identifier: 'shelter_referral',
        name: 'Shelter Referral',
        outgoing_step_form_identifier: FORMS.fetch(:shelter_referral),
        outgoing_step_name: 'Shelter Referral Details',
        version: 1,
      )
    end

    def build_outreach_referral_workflow
      build_direct_referral_workflow(
        identifier: 'outreach_referral',
        name: 'Outreach Referral',
        outgoing_step_form_identifier: FORMS.fetch(:outreach_referral),
        outgoing_step_name: 'Outreach Referral Details',
        version: 1,
      )
    end

    def build_direct_referral_workflow(identifier:, name:, outgoing_step_form_identifier:, outgoing_step_name:, version: 0)
      template = CeWorkflows::Shared::CeBuilderUtils.create_draft_template(
        identifier: identifier,
        name: name,
        data_source: @data_source,
        version: version,
      )

      provider_swimlane = template.swimlanes.find_or_create_by!(name: 'Provider')
      referrer_swimlane = template.swimlanes.find_or_create_by!(name: 'Referrer')

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.create_accept_event(template)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.create_decline_event(template)

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
      provider_decision_task = Hmis::WorkflowDefinition::UserTask.find_or_create_by!(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
      )

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

      # 3. Script task: set decline reason if referral is declined
      set_decline_reason_task = Hmis::WorkflowDefinition::ScriptTask.find_or_initialize_by(
        name: 'Set Decline Reason',
        template: template,
      )
      set_decline_reason_task.trigger_config = [
        {
          event: 'complete_step',
          message: 'set_referral_decline_reason',
          params: { 'decline_reason_field' => 'decline_reason' },
        },
      ]
      set_decline_reason_task.save!

      # Exclusive gateway for decision routing
      decision_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'provider_decision')

      # Wire up flow
      start_event.connect_to!(send_referral_task) unless start_event.outflows.exists?(target_node: send_referral_task)
      send_referral_task.connect_to!(provider_decision_task) unless send_referral_task.outflows.exists?(target_node: provider_decision_task)
      provider_decision_task.connect_to!(decision_gateway) unless provider_decision_task.outflows.exists?(target_node: decision_gateway)
      decision_gateway.connect_to!(create_enrollment_task, condition: 'decision = 1') unless decision_gateway.outflows.exists?(target_node: create_enrollment_task)
      create_enrollment_task.connect_to!(accept_event) unless create_enrollment_task.outflows.exists?(target_node: accept_event)
      decision_gateway.connect_to!(set_decline_reason_task) unless decision_gateway.outflows.exists?(target_node: set_decline_reason_task)
      set_decline_reason_task.connect_to!(decline_event) unless set_decline_reason_task.outflows.exists?(target_node: decline_event)

      template.validate!
      template
    end
  end
end
