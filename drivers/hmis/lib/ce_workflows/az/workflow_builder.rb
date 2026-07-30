###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Utility for building CE workflow definitions specific to the AZ installation.
#
# WARNING! Building these workflows will delete existing referrals and opportunities
# associated with the workflow templates (unless unsafe_run_in_production is set for
# initial production setup). Not intended for routine use in production.
#
# DeclineReason is intentionally omitted in this first iteration. After further customer
# discussion we will likely seed ReferralDeclineReason rows for client_rejected,
# provider_rejected, and canceled; add decline_reason fields on declining step forms; and
# wire set_referral_decline_reason on complete_step. HUD CE Event referral_result (2/3) is
# still set on the relevant decline paths — that is independent of DeclineReason.
module CeWorkflows::Az
  class WorkflowBuilder
    FORMS = {
      send_referral: 'mc_direct_referral_send_referral',
      initial_review: 'mc_direct_referral_initial_review',
      client_outreach: 'mc_direct_referral_client_outreach',
      provider_outcome: 'mc_direct_referral_provider_outcome',
    }.freeze

    def initialize(data_source, unsafe_run_in_production: false)
      @data_source = data_source
      @unsafe_run_in_production = unsafe_run_in_production # flag to allow running in prod ONLY for initial setup

      missing = FORMS.values - Hmis::Form::Definition.
        in_data_source(@data_source.id).
        where(role: 'CE_REFERRAL_STEP', identifier: FORMS.values).
        pluck(:identifier)
      raise "Missing CE_REFERRAL_STEP forms: #{missing.join(', ')}" if missing.any?

      raise 'This class destroys data and should not be run in production' if Rails.env.production? && !@unsafe_run_in_production
    end

    def build_mc_direct_referral_workflow
      identifier = 'mc_direct_referral'
      template_name = 'Direct Referral'
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier, data_source: @data_source) unless @unsafe_run_in_production

      puts "Creating workflow definition template '#{identifier}'"
      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, template_name, @data_source)

      ce_team_swimlane = template.swimlanes.create!(name: 'CE Team')
      provider_swimlane = template.swimlanes.create!(name: 'Provider')

      assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'assigned',
        data_source: @data_source,
      ) { |s| s.name = 'Assigned' }

      initial_review_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'initial_review',
        data_source: @data_source,
      ) { |s| s.name = 'Initial Review' }

      outreach_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'outreach',
        data_source: @data_source,
      ) { |s| s.name = 'Outreach' }

      pending_provider_decision_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'pending_provider_decision',
        data_source: @data_source,
      ) { |s| s.name = 'Pending Provider Decision' }

      status_trigger = ->(key) { { event: 'enable_step', message: 'set_custom_referral_status', params: { custom_status_key: key } } }

      start_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_start_event(template)
      accept_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_accept_event(template, update_ce_event: true) # Sets CE Event referral_result to "Successful referral: client accepted"
      decline_event = CeWorkflows::Shared::CeBuilderUtils.find_or_create_decline_event(template)

      # Task 1: Send Referral
      send_referral_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Send Referral',
        form_definition_identifier: FORMS.fetch(:send_referral),
        template: template,
        swimlane: ce_team_swimlane,
        trigger_config: [status_trigger.call(assigned_status.key)],
      )

      # Task 2: Initial Review
      initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Initial Review',
        form_definition_identifier: FORMS.fetch(:initial_review),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger.call(initial_review_status.key)],
      )

      # Task 3: Client Outreach
      client_outreach_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Client Outreach',
        form_definition_identifier: FORMS.fetch(:client_outreach),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger.call(outreach_status.key)],
      )

      # Task 4: Provider Outcome
      provider_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Outcome',
        form_definition_identifier: FORMS.fetch(:provider_outcome),
        template: template,
        swimlane: provider_swimlane,
        trigger_config: [status_trigger.call(pending_provider_decision_status.key)],
      )

      create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create CE Event',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'create_ce_event' },
        ],
      )

      create_ce_event_provider_rejected_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create CE Event with result "Unsuccessful referral: provider rejected"',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'create_ce_event' },
          { event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '3' } }, # Unsuccessful referral: provider rejected
        ],
      )

      set_ce_event_client_rejected_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: client rejected"',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '2' } }, # Unsuccessful referral: client rejected
        ],
      )

      set_ce_event_provider_rejected_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: provider rejected"',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '3' } }, # Unsuccessful referral: provider rejected
        ],
      )

      create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create Enrollment',
        template: template,
        trigger_config: [
          { event: 'complete_step', message: 'create_enrollment' },
        ],
      )

      initial_review_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'initial_review')
      client_outreach_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'client_outreach')
      provider_outcome_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'provider_outcome')

      # Start → Send Referral → Initial Review → gateway
      start_event.connect_to!(send_referral_task)
      send_referral_task.connect_to!(initial_review_task)
      initial_review_task.connect_to!(initial_review_gateway)

      # Initial Review: approve → create CE event → outreach;
      # provider_rejected → create CE event w/ result 3 → decline; cancel → decline
      initial_review_gateway.connect_to!(create_ce_event_task, condition: "initial_review_decision = 'approve'")
      initial_review_gateway.connect_to!(create_ce_event_provider_rejected_task, condition: "initial_review_decision = 'provider_rejected'")
      initial_review_gateway.connect_to!(decline_event)

      create_ce_event_task.connect_to!(client_outreach_task)
      create_ce_event_provider_rejected_task.connect_to!(decline_event)

      # Client Outreach → gateway
      client_outreach_task.connect_to!(client_outreach_gateway)
      client_outreach_gateway.connect_to!(set_ce_event_client_rejected_task, condition: "client_outreach_outcome = 'client_rejected'")
      client_outreach_gateway.connect_to!(set_ce_event_provider_rejected_task, condition: "client_outreach_outcome = 'provider_rejected'")
      client_outreach_gateway.connect_to!(provider_outcome_task)

      set_ce_event_client_rejected_task.connect_to!(decline_event)
      set_ce_event_provider_rejected_task.connect_to!(decline_event)

      # Provider Outcome → gateway → enroll/accept or decline (no Confirm Success)
      provider_outcome_task.connect_to!(provider_outcome_gateway)
      provider_outcome_gateway.connect_to!(set_ce_event_client_rejected_task, condition: "provider_outcome_decision = 'client_rejected'")
      provider_outcome_gateway.connect_to!(set_ce_event_provider_rejected_task, condition: "provider_outcome_decision = 'provider_rejected'")
      provider_outcome_gateway.connect_to!(create_enrollment_task)

      create_enrollment_task.connect_to!(accept_event)

      template.validate!
      template
    end
  end
end
