###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Utility for building the default Standard Referral CE workflow template.
# Intended for QA, staging, demo, and as a baseline when onboarding new clients.
module CeWorkflows::Standard
  class WorkflowBuilder
    FORMS = {
      initial_review: 'standard_initial_review',
      provider_decision: 'standard_provider_decision',
      confirm_placement: 'standard_confirm_placement',
      review_decline: 'standard_review_decline',
    }.freeze

    def initialize(data_source)
      @data_source = data_source

      # Validate required forms exist
      missing = FORMS.values - Hmis::Form::Definition.
        in_data_source(@data_source.id).
        where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).
        pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?
    end

    def ensure_decline_reasons
      [
        { code: 'hmis_user_error', label: 'HMIS user error' },
        { code: 'inability_to_complete_intake', label: 'Inability to complete intake' },
        { code: 'ineligible', label: 'Does not meet eligibility criteria' },
        { code: 'client_not_interested', label: 'No longer interested in this program' },
        { code: 'not_experiencing_homelessness', label: 'No longer experiencing homelessness' },
        { code: 'vacancy_no_longer_available', label: 'Estimated vacancy no longer available' },
        { code: 'enrolled_declined_hmis_data_entry', label: 'Enrolled, but declined HMIS data entry' },
      ].each do |option|
        Hmis::Ce::ReferralDeclineReason.find_or_create_by!(
          key: option[:code],
          data_source: @data_source,
        ) do |reason|
          reason.name = option[:label]
        end
      end
    end

    # Similar to PH, the standard workflow builder hard-codes its version number,
    # and is intended to be idempotent on that version number.
    # This enables iterating on a template until it is ready to be published.
    # See README_FOR_STANDARD_CE_WORKFLOWS.md for more details.
    def build_standard_referral_workflow
      find_or_create_draft_template(
        identifier: 'standard_referral',
        name: 'Standard Referral',
        version: 2,
      )
    end

    def find_or_create_draft_template(identifier:, name:, version: 0)
      template = CeWorkflows::Shared::CeBuilderUtils.find_or_create_draft_template(
        identifier: identifier,
        name: name,
        data_source: @data_source,
        version: version,
      )

      ce_team_swimlane = template.swimlanes.find_or_create_by!(name: 'CE Team')
      provider_swimlane = template.swimlanes.find_or_create_by!(name: 'Provider')

      # Statuses
      initial_review_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'initial_review',
        data_source: @data_source,
      ) { |s| s.name = 'Initial Review' }

      pending_provider_decision_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'pending_provider_decision',
        data_source: @data_source,
      ) { |s| s.name = 'Pending Provider Decision' }

      enrolled_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'enrolled',
        data_source: @data_source,
      ) { |s| s.name = 'Enrolled' }

      pending_review_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'pending_review',
        data_source: @data_source,
      ) { |s| s.name = 'Pending Review' }

      status_trigger = ->(key) { { event: 'enable_step', message: 'set_custom_referral_status', params: { custom_status_key: key } } }
      decline_reason_trigger = { event: 'complete_step', message: 'set_referral_decline_reason' }

      # Events
      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)

      # Tasks
      initial_review_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Initial Review',
        form_definition_identifier: FORMS.fetch(:initial_review),
        template: template,
        swimlane: ce_team_swimlane,
      )
      initial_review_task.trigger_config = [status_trigger.call(initial_review_status.key), decline_reason_trigger]
      initial_review_task.save!

      provider_decision_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Provider Decision',
        form_definition_identifier: FORMS.fetch(:provider_decision),
        template: template,
        swimlane: provider_swimlane,
      )
      provider_decision_task.trigger_config = [status_trigger.call(pending_provider_decision_status.key), decline_reason_trigger]
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
        swimlane: ce_team_swimlane,
      )
      confirm_placement_task.trigger_config = [status_trigger.call(enrolled_status.key)]
      confirm_placement_task.save!

      review_decline_task = Hmis::WorkflowDefinition::UserTask.find_or_initialize_by(
        name: 'Review Decline',
        form_definition_identifier: FORMS.fetch(:review_decline),
        template: template,
        swimlane: ce_team_swimlane,
      )
      review_decline_task.trigger_config = [status_trigger.call(pending_review_status.key)]
      review_decline_task.save!

      # Gateways
      initial_review_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'initial_review')
      provider_decision_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'provider_decision')
      review_decline_gateway = CeWorkflows::Shared::CeBuilderUtils.find_or_create_gateway(template, 'review_decline')

      # Wire up flow
      start_event.connect_to!(initial_review_task) unless start_event.outflows.exists?(target_node: initial_review_task)
      initial_review_task.connect_to!(initial_review_gateway) unless initial_review_task.outflows.exists?(target_node: initial_review_gateway)
      initial_review_gateway.connect_to!(decline_event, condition: "initial_review_decision = 'decline'") unless initial_review_gateway.outflows.exists?(target_node: decline_event)
      initial_review_gateway.connect_to!(provider_decision_task) unless initial_review_gateway.outflows.exists?(target_node: provider_decision_task)

      provider_decision_task.connect_to!(provider_decision_gateway) unless provider_decision_task.outflows.exists?(target_node: provider_decision_gateway)
      provider_decision_gateway.connect_to!(review_decline_task, condition: "provider_decision = 'decline'") unless provider_decision_gateway.outflows.exists?(target_node: review_decline_task)
      provider_decision_gateway.connect_to!(enroll_client_task) unless provider_decision_gateway.outflows.exists?(target_node: enroll_client_task)

      enroll_client_task.connect_to!(confirm_placement_task) unless enroll_client_task.outflows.exists?(target_node: confirm_placement_task)
      confirm_placement_task.connect_to!(accept_event) unless confirm_placement_task.outflows.exists?(target_node: accept_event)

      review_decline_task.connect_to!(review_decline_gateway) unless review_decline_task.outflows.exists?(target_node: review_decline_gateway)
      review_decline_gateway.connect_to!(decline_event, condition: "admin_decision = 'approve_decline'") unless review_decline_gateway.outflows.exists?(target_node: decline_event)
      review_decline_gateway.connect_to!(provider_decision_task) unless review_decline_gateway.outflows.exists?(target_node: provider_decision_task)

      template.validate!
      template
    end
  end
end
