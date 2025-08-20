###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

##
# Utility for building Coordinated Entry (CE) workflow definitions specific to the AC implementation.
# Intended for use in scripts and Rake tasks that automate the setup or teardown of AC CE workflows.
#
# WARNING! Building these workflows will delete existing referrals and opportunities associated with the workflow templates.
# Not intended for use in production.
module CeWorkflows::Ac
  class WorkflowBuilder
    CE_STEP_FORMS = {
      initial_review: 'housing_workflow_initial_review',
      initial_client_engagement: 'housing_workflow_initial_client_engagement',
      client_engagement: 'housing_workflow_client_engagement',
      client_offer_outcome: 'housing_workflow_client_offer_outcome',
      # These 3 provider outcome forms are the same, but collect onto different custom data element definitions.
      # Could have used the same form for all, but felt that having unique cdeds would simplify reporting.
      provider_outcome_1: 'housing_workflow_provider_outcome_1',
      provider_outcome_2: 'housing_workflow_provider_outcome_2',
      provider_outcome_3: 'housing_workflow_provider_outcome_3',
      # change_provider_outcome is a variant on the provider_outcome forms. It is an optional task
      # used for moving a referral into the denial workflow even after the provider initially accepted
      change_provider_outcome: 'change_provider_outcome',
      # First 2 denial review forms are the same. The third one is slightly different because it only allows "approving" the denial,
      # since it can no longer be sent back to the provider. Use 3 different forms for the same reason as above.
      denial_review_1: 'housing_workflow_denial_review_1',
      denial_review_2: 'housing_workflow_denial_review_2',
      denial_review_3: 'housing_workflow_denial_review_3',
      confirm_success: 'housing_workflow_confirm_success',
      # First step in non-housing direct referral workflows
      initial_outgoing_referral: 'admin_assign_workflow_initial_outgoing_referral',
    }.freeze

    def initialize(data_source, unsafe_run_in_production: false)
      @data_source = data_source
      @unsafe_run_in_production = unsafe_run_in_production # flag to allow running in prod ONLY for initial setup

      # validate forms exist
      missing_identifiers = CE_STEP_FORMS.values - Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: CE_STEP_FORMS.values).pluck(:identifier)
      raise "Some form definitions are missing. Did you run 'rails driver:hmis:seed_definitions'? #{missing_identifiers.join(', ')}" if missing_identifiers.any?

      raise 'This class destroys data and should not be run in production' if Rails.env.production? && !@unsafe_run_in_production
    end

    # This method builds the AC housing workflow, which is a referral workflow for housing opportunities.
    # TODO: make this more ergonomic for Direct Referrals (used for housing transfers). The "continue workflow" field doesn't make sense in that scenario.
    def build_housing_workflow
      identifier = 'housing_workflow_v1'
      template_name = 'Housing Referral Workflow V1'
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier) unless @unsafe_run_in_production

      puts "Creating workflow definition template '#{identifier}'"
      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, template_name, @data_source)

      # Create Swimlanes
      ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
      project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

      # Create Statuses
      matching_in_progress_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'matching_in_progress',
        name: 'Matching In Progress',
        data_source: @data_source,
      )
      matching_in_progress_status_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': matching_in_progress_status.key } }]

      start_event = CeWorkflows::Shared::CeBuilderUtils.create_start_event(template)

      initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Initial Review',
        form_definition_identifier: CE_STEP_FORMS.fetch(:initial_review),
        template: template,
        swimlane: ce_staff_swimlane,
        trigger_config: matching_in_progress_status_trigger_config,
      )
      initial_client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Initial Client Engagement',
        form_definition_identifier: CE_STEP_FORMS.fetch(:initial_client_engagement),
        template: template,
        swimlane: ce_staff_swimlane,
      )
      client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Client Engagement',
        form_definition_identifier: CE_STEP_FORMS.fetch(:client_engagement),
        template: template,
        swimlane: ce_staff_swimlane,
      )

      client_offer_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Client Offer Outcome',
        form_definition_identifier: CE_STEP_FORMS.fetch(:client_offer_outcome),
        template_id: template.id,
        swimlane: ce_staff_swimlane,
        trigger_config: [
          {
            event: 'enable_step',
            message: 'create_ce_event',
          },
        ],
      )

      # Build the provider outcome and denial review loop. This is shared with the housing workflow.
      loop_nodes = build_provider_outcome_denial_review_loop(
        template: template,
        ce_staff_swimlane: ce_staff_swimlane,
        project_staff_swimlane: project_staff_swimlane,
      )
      provider_outcome_task_1 = loop_nodes[:provider_outcome_task_1]
      admin_decline_gateway = loop_nodes[:admin_decline_gateway]

      # Start Referral => Initial Review
      start_event.connect_to!(initial_review_task)

      # Initial Review => Gateway => Initial Client Engagement (or Decline)
      initial_review_task_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'initial_review_task')
      initial_review_task.connect_to!(initial_review_task_gateway)
      initial_review_task_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0') # admin decline
      initial_review_task_gateway.connect_to!(initial_client_engagement_task) # happy path: move to next task

      # Initial Client Engagement => Client Engagement
      initial_client_engagement_task.connect_to!(client_engagement_task) # TODO CONFIRM: can't bail out from this point?

      # Client Engagement => Gateway => Client Offer Outcome (or Decline)
      client_engagement_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'client_engagement_task')
      client_engagement_task.connect_to!(client_engagement_gateway)
      client_engagement_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0') # admin decline
      client_engagement_gateway.connect_to!(client_offer_outcome_task) # happy path: move to next task

      # Client Offer Outcome => Gateway => Provider Outcome 1 (or Decline)
      client_offer_outcome_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'client_offer_outcome')
      client_offer_outcome_task.connect_to!(client_offer_outcome_gateway)
      client_offer_outcome_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0')
      client_offer_outcome_gateway.connect_to!(provider_outcome_task_1) # happy path: continue to provider outcome task

      # REST IS HANDLED BY THE SHARED "DENIAL REVIEW LOOP" CODE

      template.validate!

      puts(template.to_mermaid_diagram)

      template
    end

    # This method builds the Admin Assign workflow, which is a workflow meant to be used for direct (outgoing) referrals to non-housing projects
    def build_admin_assign_workflow
      identifier = 'admin_assign_workflow'
      template_name = 'Admin Assign Workflow'
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data(identifier) unless @unsafe_run_in_production

      puts "Creating workflow definition template '#{identifier}'"
      template = CeWorkflows::Shared::CeBuilderUtils.create_template(identifier, template_name, @data_source)

      # Create Swimlanes
      ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
      project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

      # Create Statuses
      assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'assigned',
        name: 'Assigned',
        data_source: @data_source,
      )

      # Start Event
      start_event = CeWorkflows::Shared::CeBuilderUtils.create_start_event(template)

      # Initial Outgoing Referral Task
      initial_outgoing_referral_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Admin Assign',
        form_definition_identifier: CE_STEP_FORMS.fetch(:initial_outgoing_referral),
        template: template,
        swimlane: ce_staff_swimlane, # assignment doesn't really matter since it gets sent directly?
        trigger_config: [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': assigned_status.key } }],
      )

      # Script Task to create CE Event
      create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create CE Event',
        template_id: template.id,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_ce_event',
          },
        ],
      )

      # Start Referral => Initial Review
      start_event.connect_to!(initial_outgoing_referral_task)

      # Initial Outgoing Referral Task => CE Event
      initial_outgoing_referral_task.connect_to!(create_ce_event_task)

      # Build the provider outcome and denial review loop. This is shared with the housing workflow.
      loop_nodes = build_provider_outcome_denial_review_loop(
        template: template,
        ce_staff_swimlane: ce_staff_swimlane,
        project_staff_swimlane: project_staff_swimlane,
      )
      provider_outcome_task_1 = loop_nodes[:provider_outcome_task_1]

      # Connect the CE Event creation to the first provider outcome task
      create_ce_event_task.connect_to!(provider_outcome_task_1)

      # REST IS HANDLED BY THE SHARED "DENIAL REVIEW LOOP" CODE

      template.validate!

      puts(template.to_mermaid_diagram)

      template
    end

    private

    # Shared code for building provider outcome and denial review loop.
    # The provider can deny the referral up to three times, with a denial review step after each denial.
    # If the provider denies the referral three times, it goes to a final denial review step. From there,
    # the denial must be accepted (aka the referral must be declined).
    #
    # This loop also handles:
    # - Updating custom referral status to 'Assigned' or 'Denial Pending' as appropriate
    # - Setting the CE Event result (both for decline and accept)
    # - Generating the target Enrollment when the referral is accepted by the provider
    def build_provider_outcome_denial_review_loop(template:, ce_staff_swimlane:, project_staff_swimlane:)
      # Statuses
      assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'assigned',
        name: 'Assigned',
        data_source: @data_source,
      )
      denied_pending_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'denial_pending',
        name: 'Denial Pending',
        data_source: @data_source,
      )
      enrolled_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: 'enrolled',
        name: 'Enrolled',
        data_source: @data_source,
      )
      denied_pending_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': denied_pending_status.key } }]
      assigned_status_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': assigned_status.key } }]
      enrolled_status_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': enrolled_status.key } }]

      # Provider Outcome User Tasks
      provider_outcome_task_1 = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Outcome',
        form_definition_identifier: CE_STEP_FORMS.fetch(:provider_outcome_1),
        template_id: template.id,
        swimlane: project_staff_swimlane,
        trigger_config: assigned_status_trigger_config,
      )
      provider_outcome_task_2 = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Outcome (Second Attempt)',
        form_definition_identifier: CE_STEP_FORMS.fetch(:provider_outcome_2),
        template_id: template.id,
        swimlane: project_staff_swimlane,
        trigger_config: assigned_status_trigger_config,
      )
      provider_outcome_task_3 = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Provider Outcome (Third Attempt)',
        form_definition_identifier: CE_STEP_FORMS.fetch(:provider_outcome_3),
        template_id: template.id,
        swimlane: project_staff_swimlane,
        trigger_config: assigned_status_trigger_config,
      )

      # Denial Review User Tasks
      denial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Denial Review',
        form_definition_identifier: CE_STEP_FORMS.fetch(:denial_review_1),
        template_id: template.id,
        swimlane: ce_staff_swimlane,
        trigger_config: denied_pending_trigger_config,
      )
      denial_review_task_2 = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Denial Review (Second)',
        form_definition_identifier: CE_STEP_FORMS.fetch(:denial_review_2),
        template_id: template.id,
        swimlane: ce_staff_swimlane,
        trigger_config: denied_pending_trigger_config,
      )
      denial_review_task_3 = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Denial Review (Third)',
        form_definition_identifier: CE_STEP_FORMS.fetch(:denial_review_3),
        template_id: template.id,
        swimlane: ce_staff_swimlane,
        trigger_config: denied_pending_trigger_config,
      )

      # Confirm Success User Task
      confirm_success_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Confirm Success',
        form_definition_identifier: CE_STEP_FORMS.fetch(:confirm_success),
        template_id: template.id,
        swimlane: ce_staff_swimlane,
        trigger_config: enrolled_status_trigger_config,
      )

      # Change Provider Outcome optional user task
      change_provider_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
        name: 'Change Provider Outcome (Optional)',
        form_definition_identifier: CE_STEP_FORMS.fetch(:change_provider_outcome),
        template_id: template.id,
        swimlane: project_staff_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'disable_step',
            params: { 'node_id': confirm_success_task.id },
          },
        ],
      )

      # Script Tasks
      provider_rejects_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: provider rejected"',
        template_id: template.id,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'set_ce_event_result',
            params: { referral_result: '3' },
          },
        ],
      )
      client_rejects_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Update CE Event with result "Unsuccessful referral: client rejected"',
        template_id: template.id,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'set_ce_event_result',
            params: { referral_result: '2' },
          },
        ],
      )
      create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
        name: 'Create Enrollment',
        template_id: template.id,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_enrollment',
          },
        ],
      )

      # Events
      accept_event = CeWorkflows::Shared::CeBuilderUtils.create_accept_event(template, update_ce_event: true)
      decline_event = CeWorkflows::Shared::CeBuilderUtils.create_decline_event(template)

      # Set up gateway for declining that closes the CE Event if a ReferralResult outcome has been specified.
      # If neither condition matches, it declines the referral without updating the CE Event.
      # NOTE: this depends on forms being set up correctly so they collect referral_result if a CE Event has been created.
      admin_decline_gateway = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'admin_decline_gateway')
      admin_decline_gateway.connect_to!(client_rejects_ce_event_task, condition: 'referral_result = 2')
      admin_decline_gateway.connect_to!(provider_rejects_ce_event_task, condition: 'referral_result = 3')
      admin_decline_gateway.connect_to!(decline_event)
      client_rejects_ce_event_task.connect_to!(decline_event)
      provider_rejects_ce_event_task.connect_to!(decline_event)

      # Provider Outcome 1 => Gateway => Denial Review 1 OR Create Enrollment (Script)
      provider_outcome_gateway_1 = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'provider_outcome_1')
      provider_outcome_task_1.connect_to!(provider_outcome_gateway_1)
      provider_outcome_gateway_1.connect_to!(denial_review_task, condition: 'move_forward = 0')
      provider_outcome_gateway_1.connect_to!(create_enrollment_task)

      # Provider Outcome 2 => Gateway => Denial Review 2 OR Create Enrollment (Script)
      provider_outcome_gateway_2 = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'provider_outcome_2')
      provider_outcome_task_2.connect_to!(provider_outcome_gateway_2)
      provider_outcome_gateway_2.connect_to!(denial_review_task_2, condition: 'move_forward = 0')
      provider_outcome_gateway_2.connect_to!(create_enrollment_task)

      # Provider Outcome 3 => Gateway => Denial Review 3 OR Create Enrollment (Script)
      provider_outcome_gateway_3 = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'provider_outcome_3')
      provider_outcome_task_3.connect_to!(provider_outcome_gateway_3)
      provider_outcome_gateway_3.connect_to!(denial_review_task_3, condition: 'move_forward = 0')
      provider_outcome_gateway_3.connect_to!(create_enrollment_task)

      # Denial Review 1 => Gateway => Decline OR send back to Provider Outcome
      denial_review_gateway_1 = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'denial_review_1')
      denial_review_task.connect_to!(denial_review_gateway_1)
      denial_review_gateway_1.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1') # Accept Denial
      denial_review_gateway_1.connect_to!(provider_outcome_task_2) # "Send back" to next attempt at Provider Outcome

      # Denial Review 2 => Gateway => Decline OR send back to Provider Outcome
      denial_review_gateway_2 = CeWorkflows::Shared::CeBuilderUtils.create_gateway(template, 'denial_review_2')
      denial_review_task_2.connect_to!(denial_review_gateway_2)
      denial_review_gateway_2.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1') # Accept Denial
      denial_review_gateway_2.connect_to!(provider_outcome_task_3) # "Send back" to next attempt at Provider Outcome

      # Denial Review 2 => Gateway => Decline. Cannot be "sent back" to Provider Outcome.
      denial_review_task_3.connect_to!(admin_decline_gateway)

      # Create Enrollment (Script) => Confirm Success Task
      create_enrollment_task.connect_to!(confirm_success_task)

      # Create Enrollment (Script) => Change Provider Outcome *optional* task that re-triggers the Denial Review
      create_enrollment_task.connect_to!(change_provider_outcome_task)
      change_provider_outcome_task.connect_to!(denial_review_task)

      confirm_success_task.connect_to!(accept_event)
      {
        provider_outcome_task_1: provider_outcome_task_1,
        admin_decline_gateway: admin_decline_gateway,
      }
    end
  end
end
