# This task is for developing and iterating on CE workflow definitions.
# It will be run in staging/training environments until the workflows are ready, at which point we will run it in production.
# CAUTION: It deletes existing referrals and opportunities, so that we don't have to worry about definitions shifting underfoot.
# This means it should NOT be run in production after the first time!
# Usage: rails driver:hmis:ce_define_workflows

module CeWorkflowBuilder
  def self.delete_template_and_associated_data(template_identifier)
    puts "Deleting existing CE data associated with #{template_identifier}"

    templates = Hmis::WorkflowDefinition::Template.where(identifier: template_identifier)
    opportunities = Hmis::Ce::Opportunity.where(workflow_template_identifier: template_identifier)
    instances = Hmis::WorkflowExecution::Instance.where(template: templates)
    steps = Hmis::WorkflowExecution::Step.where(instance: instances)
    referrals = Hmis::Ce::Referral.where(workflow_instance: instances)

    Hmis::Ce::ReferralNote.where(referral: referrals).destroy_all
    Hmis::Ce::ReferralParticipant.where(referral: referrals).destroy_all
    referrals.destroy_all

    Hmis::Ce::OpportunityCategorization.where(opportunity: opportunities).destroy_all
    opportunities.destroy_all

    Hmis::WorkflowExecution::AuditEvent.where(instance: instances).destroy_all
    instances.destroy_all
    Hmis::WorkflowExecution::StepAssignment.where(step: steps).destroy_all
    steps.destroy_all

    Hmis::WorkflowDefinition::Flow.where(template: templates).destroy_all
    Hmis::WorkflowDefinition::Node.where(template: templates).destroy_all
    Hmis::WorkflowDefinition::Swimlane.where(template: templates).destroy_all
    templates.destroy_all
  end

  def self.delete_form_definitions(form_definition_identifiers)
    puts "Deleting form definitions #{form_definition_identifiers.join(', ')}"

    # Temporarily disable the callback that prevents destroying published forms
    Hmis::Form::Definition.skip_callback(:destroy, :before, :can_be_destroyed)
    Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: form_definition_identifiers).destroy_all
    Hmis::Form::Definition.set_callback(:destroy, :before, :can_be_destroyed) # re-enable callback
  end

  def self.create_template(identifier, name, data_source)
    Hmis::WorkflowDefinition::Template.create!(
      identifier: identifier,
      name: name,
      data_source: data_source,
      template_type: 'ce_referral',
      status: 'published',
      version: 0,
    )
  end

  def self.create_start_event(template)
    Hmis::WorkflowDefinition::StartEvent.create!(
      name: 'Start Referral',
      template: template,
      trigger_config: [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ],
    )
  end

  def self.create_accept_event(template, update_ce_event: false)
    Hmis::WorkflowDefinition::EndEvent.create!(
      name: 'Referral Accepted',
      template: template,
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
        },
        *(
          if update_ce_event
            [
              {
                event: 'end_workflow',
                message: 'set_ce_event_result',
                params: { referral_result: '1' },
              },
            ]
          end
        ),
      ].compact,
    )
  end

  def self.create_gateway(template, name, gateway_type: 'exclusive')
    Hmis::WorkflowDefinition::Gateway.create!(
      template: template,
      gateway_type: gateway_type,
      name: "#{gateway_type.capitalize} Gateway: #{name}",
    )
  end

  def self.create_decline_event(template)
    Hmis::WorkflowDefinition::EndEvent.create!(
      name: 'Referral Declined',
      template: template,
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
        },
      ],
    )
  end

  # This method builds the QA housing workflow version 1, which is a referral workflow for housing opportunities.
  # Future improvements:
  # - Generate Custom Data Element Definitions (CDEDs) for the form fields, for reporting. Update field keys as appropriate.
  # - Refine forms and workflow
  # - Clean up decline reasons, they are copy-pasted across forms
  def self.build_housing_workflow_v1(data_source)
    identifier = 'housing_workflow_v1'
    template_name = 'Housing Referral Workflow V1'
    delete_template_and_associated_data(identifier)

    # form identifiers
    workflow_form_identifiers = {
      initial_review: 'housing_workflow_initial_review',
      initial_client_engagement: 'housing_workflow_initial_client_engagement',
      client_engagement: 'housing_workflow_client_engagement',
      client_offer_outcome: 'housing_workflow_client_offer_outcome',
      provider_outcome_1: 'housing_workflow_provider_outcome_1',
      provider_outcome_2: 'housing_workflow_provider_outcome_2',
      provider_outcome_3: 'housing_workflow_provider_outcome_3',
      denial_review_1: 'housing_workflow_denial_review_1',
      denial_review_2: 'housing_workflow_denial_review_2',
      denial_review_3: 'housing_workflow_denial_review_3',
      confirm_success: 'housing_workflow_confirm_success',
    }.freeze

    missing_identifiers = workflow_form_identifiers.values - Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: workflow_form_identifiers.values).pluck(:identifier)
    raise "Some form definitions are missing. Did you run 'rails driver:hmis:seed_definitions'? #{missing_identifiers.join(', ')}" if missing_identifiers.any?

    puts "Creating workflow definition template '#{identifier}'"
    template = create_template(identifier, template_name, data_source)

    # Create Swimlanes
    ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
    project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

    # Create Statuses
    matching_in_progress_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'matching_in_progress',
      name: 'Matching In Progress',
      data_source: data_source,
    )
    assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'assigned',
      name: 'Assigned',
      data_source: data_source,
    )
    denied_pending_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'denial_pending',
      name: 'Denial Pending',
      data_source: data_source,
    )
    denied_pending_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': denied_pending_status.key }}]
    assigned_status_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': assigned_status.key }}]
    matching_in_progress_status_trigger_config = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': matching_in_progress_status.key }}]

    start_event = create_start_event(template)

    initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Initial Review',
      form_definition_identifier: workflow_form_identifiers.fetch(:initial_review),
      template: template,
      swimlane: ce_staff_swimlane,
      trigger_config: matching_in_progress_status_trigger_config,
    )
    initial_client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Initial Client Engagement',
      form_definition_identifier: workflow_form_identifiers.fetch(:initial_client_engagement),
      template: template,
      swimlane: ce_staff_swimlane,
    )
    client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Client Engagement',
      form_definition_identifier: workflow_form_identifiers.fetch(:client_engagement),
      template: template,
      swimlane: ce_staff_swimlane,
    )

    create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Create CE Event',
      template_id: template.id,
      trigger_config: [
        {
          event: 'complete_step', # enable_step doesn't work for script tasks. we should validate it since its ignored.
          message: 'create_ce_event',
        },
      ],
    )

    client_offer_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Client Offer Outcome',
      form_definition_identifier: workflow_form_identifiers.fetch(:client_offer_outcome),
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      # TODO can we do this? instead of having a separate ScriptTask for it
      # trigger_config: [
      #   {
      #     event: 'enable_step',
      #     message: 'create_ce_event',
      #   },
      # ],
    )

    provider_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome',
      form_definition_identifier: workflow_form_identifiers.fetch(:provider_outcome_1),
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger_config,
    )
    provider_outcome_task_2 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome (Second Attempt)',
      form_definition_identifier: workflow_form_identifiers.fetch(:provider_outcome_2),
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger_config,
    )
    provider_outcome_task_3 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome (Third Attempt)',
      form_definition_identifier: workflow_form_identifiers.fetch(:provider_outcome_3),
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger_config,
    )

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

    # denied pending ("Provider Outcome")=> send back ("Denial Review" task)
    # denied pending ("Provider Outcome 2")=> send back ("Denial Review 2" task)
    # denied pending ("Provider Outcome 3")=> ("Denial Review 3" task) can no longer send back. denial review must accept the denial. different form.

    denial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review',
      form_definition_identifier: workflow_form_identifiers.fetch(:denial_review_1),
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger_config,
    )

    denial_review_task_2 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review (Second)',
      form_definition_identifier: workflow_form_identifiers.fetch(:denial_review_2),
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger_config,
    )

    denial_review_task_3 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review (Third)',
      form_definition_identifier: workflow_form_identifiers.fetch(:denial_review_3),
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger_config,
    )

    confirm_success_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Confirm Success',
      form_definition_identifier: workflow_form_identifiers.fetch(:confirm_success),
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      # Keeping commented-out as example for testing, but don't need in workflow
      # trigger_config: [
      #   {
      #     event: 'complete_step',
      #     message: 'set_move_in_date',
      #   },
      # ],
    )

    accept_event = create_accept_event(template, update_ce_event: true)
    decline_event = create_decline_event(template)

    # Set up gateway for declining that closes the CE Event if a ReferralResult outcome has been specified.
    # If neither condition matches, it declines the referral without updating the CE Event.
    # NOTE: this depends on forms being set up correctly so they collect referral_result if a CE Event has been created.
    admin_decline_gateway = create_gateway(template, 'admin_decline_gateway')
    admin_decline_gateway.connect_to!(client_rejects_ce_event_task, condition: 'referral_result = UNSUCCESSFUL_REFERRAL_CLIENT_REJECTED')
    admin_decline_gateway.connect_to!(provider_rejects_ce_event_task, condition: 'referral_result = UNSUCCESSFUL_REFERRAL_PROVIDER_REJECTED')
    admin_decline_gateway.connect_to!(decline_event)
    client_rejects_ce_event_task.connect_to!(decline_event)
    provider_rejects_ce_event_task.connect_to!(decline_event)

    # Start Referral => Initial Review
    start_event.connect_to!(initial_review_task)

    # Initial Review => Gateway => Initial Client Engagement (or Decline)
    initial_review_task_gateway = create_gateway(template, 'initial_review_task')
    initial_review_task.connect_to!(initial_review_task_gateway)
    initial_review_task_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0') # admin decline
    initial_review_task_gateway.connect_to!(initial_client_engagement_task) # happy path: move to next task

    # Initial Client Engagement => Client Engagement
    initial_client_engagement_task.connect_to!(client_engagement_task) # can't bail out from this point?

    # Client Engagement => Gateway => Create CE Event (Script) (or Decline)
    client_engagement_gateway = create_gateway(template, 'client_engagement_task')
    client_engagement_task.connect_to!(client_engagement_gateway)
    client_engagement_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0') # admin decline
    client_engagement_gateway.connect_to!(create_ce_event_task) # happy path: create CE event

    # Create CE Event (Script) => Client Offer Outcome
    create_ce_event_task.connect_to!(client_offer_outcome_task)

    # Client Offer Outcome => Gateway => Provider Outcome 1 (or Decline)
    client_offer_outcome_gateway = create_gateway(template, 'client_offer_outcome')
    client_offer_outcome_task.connect_to!(client_offer_outcome_gateway)
    client_offer_outcome_gateway.connect_to!(admin_decline_gateway, condition: 'move_forward = 0')
    client_offer_outcome_gateway.connect_to!(provider_outcome_task) # happy path: continue to provider outcome

    # Provider Outcome 1 => Gateway => Denial Review 1 OR Create Enrollment (Script)
    provider_outcome_gateway_1 = create_gateway(template, 'provider_outcome_1')
    provider_outcome_task.connect_to!(provider_outcome_gateway_1)
    provider_outcome_gateway_1.connect_to!(denial_review_task, condition: 'move_forward = 0')
    provider_outcome_gateway_1.connect_to!(create_enrollment_task)

    # Provider Outcome 2 => Gateway => Denial Review 2 OR Create Enrollment (Script)
    provider_outcome_gateway_2 = create_gateway(template, 'provider_outcome_2')
    provider_outcome_task_2.connect_to!(provider_outcome_gateway_2)
    provider_outcome_gateway_2.connect_to!(denial_review_task_2, condition: 'move_forward = 0')
    provider_outcome_gateway_2.connect_to!(create_enrollment_task)

    # Provider Outcome 3 => Gateway => Denial Review 3 OR Create Enrollment (Script)
    provider_outcome_gateway_3 = create_gateway(template, 'provider_outcome_3')
    provider_outcome_task_3.connect_to!(provider_outcome_gateway_3)
    provider_outcome_gateway_3.connect_to!(denial_review_task_3, condition: 'move_forward = 0')
    provider_outcome_gateway_3.connect_to!(create_enrollment_task)

    # Denial Review 1 => Gateway => Decline OR send back to Provider Outcome
    denial_review_gateway_1 = create_gateway(template, 'denial_review_1')
    denial_review_task.connect_to!(denial_review_gateway_1)
    denial_review_gateway_1.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1') # Accept Denial
    denial_review_gateway_1.connect_to!(provider_outcome_task_2) # "Send back" to next attempt at Provider Outcome

    # Denial Review 2 => Gateway => Decline OR send back to Provider Outcome
    denial_review_gateway_2 = create_gateway(template, 'denial_review_2')
    denial_review_task_2.connect_to!(denial_review_gateway_2)
    denial_review_gateway_2.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1') # Accept Denial
    denial_review_gateway_2.connect_to!(provider_outcome_task_3) # "Send back" to next attempt at Provider Outcome

    # Denial Review 2 => Gateway => Decline. Cannot be "sent back" to Provider Outcome.
    denial_review_task_3.connect_to!(admin_decline_gateway)

    # Create Enrollment (Script) => Confirm Success Task
    create_enrollment_task.connect_to!(confirm_success_task)

    # Confirm Success Task => Accept Event
    confirm_success_task.connect_to!(admin_decline_gateway, condition: 'move_forward = 0')
    confirm_success_task.connect_to!(accept_event, condition: 'move_forward = 1')

    template.validate!

    puts(template.to_mermaid_diagram)

    template
  end
end

desc 'Script to create CE workflow definition'
task ce_define_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?
  raise unless HmisEnforcement.hmis_enabled?

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  data_source = GrdaWarehouse::DataSource.hmis.order(:id).first

  HmisUtil::CeBuilder.create_state_machine_custom_statuses(data_source)

  puts "Creating workflow templates in data source #{data_source.id} (#{data_source.name})"
  CeWorkflowBuilder.build_housing_workflow_v1(data_source)

  # define more functions in Hmis::Ce::WorkflowBuilder and call them here to create additional templates, like:
  # Hmis::Ce::WorkflowBuilder.create_xyz_template(data_source)
end
