###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Utility for building CE workflow definitions specific to the Demo installation.
module CeWorkflows::Demo
  class WorkflowBuilder
    FORMS = {
      coc_initial_review: 'demo_coc_initial_review',
      provider_decision: 'demo_provider_decision',
      confirm_placement: 'demo_confirm_placement',
      review_decline: 'demo_review_decline',
    }.freeze

    def initialize(data_source)
      @data_source = data_source

      # Validate required forms exist
      missing = FORMS.values - Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?
    end

    def ensure_decline_reasons
      [
        { 'code': 'referral_sent_in_error', 'label': 'Referral sent in error' },
        { 'code': 'ineligible', 'label': 'Does not meet eligibility criteria' },
        { 'code': 'enrolled_in_equivalent_service', 'label': 'Enrolled in equivalent service with another provider' },
        { 'code': 'unable_to_locate_client', 'label': 'Unable to contact/locate' },
        { 'code': 'client_not_interested', 'label': 'No longer interested in the program' },
        { 'code': 'other', 'label': 'Other (detail in notes section)' },
      ].each do |option|
        Hmis::Ce::ReferralDeclineReason.find_or_create_by!(
          key: option[:code],
          data_source: @data_source,
        ) do |reason|
          reason.name = option[:label]
        end
      end
    end

    def build_standard_referral_workflow
      find_or_create_draft_template(
        identifier: 'standard_referral',
        name: 'Standard Referral',
        version: 1,
      )
    end

    def find_or_create_draft_template(identifier:, name:, version: 0)
      template = CeWorkflows::Shared::CeBuilderUtils.find_or_create_draft_template(
        identifier: identifier,
        name: name,
        data_source: @data_source,
        version: version,
      )

      coc_lead_swimlane = template.swimlanes.find_or_create_by!(name: 'CoC Lead')
      provider_swimlane = template.swimlanes.find_or_create_by!(name: 'Provider')

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)

      # Tasks
      coc_initial_review_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'CoC Initial Review',
        form_definition_identifier: FORMS.fetch(:coc_initial_review),
        template: template,
        swimlane: coc_lead_swimlane,
      )
      coc_initial_review_task.save!

      provider_decision_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
      )
      provider_decision_task.save!

      enroll_client_task = Hmis::WorkflowDefinition::ScriptTask.find_or_initialize_by(
        name: 'Create Enrollment',
        template: template,
      )
      enroll_client_task.trigger_config = [
        {
          event: 'complete_step',
          message: 'create_enrollment',
        },
      ]
      enroll_client_task.save!

      confirm_placement_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Confirm Placement',
        form_definition_identifier: FORMS.fetch(:confirm_placement),
        template: template,
        swimlane: coc_lead_swimlane,
      )
      confirm_placement_task.save!

      review_decline_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Review Decline',
        form_definition_identifier: FORMS.fetch(:review_decline),
        template: template,
        swimlane: coc_lead_swimlane,
      )
      review_decline_task.save!

      # Gateways
      coc_review_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'coc_initial_review')
      provider_decision_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'provider_decision')
      review_decline_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'review_decline')

      # Wire up flow
      start_event.connect_to!(coc_initial_review_task) unless start_event.outflows.exists?(target_node: coc_initial_review_task)
      coc_initial_review_task.connect_to!(coc_review_gateway) unless coc_initial_review_task.outflows.exists?(target_node: coc_review_gateway)
      # Exclusive gateway: one default (no condition) outflow is required — see WorkflowTemplateValidator.
      coc_review_gateway.connect_to!(decline_event, condition: 'decision = "decline"') unless coc_review_gateway.outflows.exists?(target_node: decline_event)
      coc_review_gateway.connect_to!(provider_decision_task) unless coc_review_gateway.outflows.exists?(target_node: provider_decision_task)

      provider_decision_task.connect_to!(provider_decision_gateway) unless provider_decision_task.outflows.exists?(target_node: provider_decision_gateway)
      provider_decision_gateway.connect_to!(review_decline_task, condition: 'decision = "decline"') unless provider_decision_gateway.outflows.exists?(target_node: review_decline_task)
      provider_decision_gateway.connect_to!(enroll_client_task) unless provider_decision_gateway.outflows.exists?(target_node: enroll_client_task)

      enroll_client_task.connect_to!(confirm_placement_task) unless enroll_client_task.outflows.exists?(target_node: confirm_placement_task)
      confirm_placement_task.connect_to!(accept_event) unless confirm_placement_task.outflows.exists?(target_node: accept_event)

      review_decline_task.connect_to!(review_decline_gateway) unless review_decline_task.outflows.exists?(target_node: review_decline_gateway)
      review_decline_gateway.connect_to!(decline_event, condition: 'decision = "approve_decline"') unless review_decline_gateway.outflows.exists?(target_node: decline_event)
      review_decline_gateway.connect_to!(provider_decision_task) unless review_decline_gateway.outflows.exists?(target_node: provider_decision_task)

      template.validate!
      template
    end
  end
end
