class AcHmisCeWorkflowBuilder
  def initialize(data_source)
    @data_source = data_source
  end

  def build_housing_workflow_v1
    identifier = 'housing_workflow_v1'
    template_name = 'Housing Referral Workflow V1'
    form_ids = {
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
    }
    CeWorkflowBuilder.delete_template_and_associated_data(identifier)
    template = CeWorkflowBuilder.create_template(identifier, template_name, @data_source)
    ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
    project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

    # Statuses
    matching_in_progress_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'matching_in_progress', name: 'Matching In Progress', data_source: @data_source
    )
    assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'assigned', name: 'Assigned', data_source: @data_source
    )
    denied_pending_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'denial_pending', name: 'Denial Pending', data_source: @data_source
    )
    matching_in_progress_trigger = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': matching_in_progress_status.key }}]
    assigned_status_trigger = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': assigned_status.key }}]
    denied_pending_trigger = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': denied_pending_status.key }}]

    # Unique beginning
    start_event = CeWorkflowBuilder.create_start_event(template)
    initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Initial Review',
      form_definition_identifier: form_ids[:initial_review],
      template: template,
      swimlane: ce_staff_swimlane,
      trigger_config: matching_in_progress_trigger,
    )
    initial_client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Initial Client Engagement',
      form_definition_identifier: form_ids[:initial_client_engagement],
      template: template,
      swimlane: ce_staff_swimlane,
    )
    client_engagement_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Client Engagement',
      form_definition_identifier: form_ids[:client_engagement],
      template: template,
      swimlane: ce_staff_swimlane,
    )
    client_offer_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Client Offer Outcome',
      form_definition_identifier: form_ids[:client_offer_outcome],
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: [{ event: 'enable_step', message: 'create_ce_event' }],
    )

    # Shared loop
    loop_nodes = build_provider_outcome_denial_review_loop(
      template: template,
      form_ids: form_ids,
      ce_staff_swimlane: ce_staff_swimlane,
      project_staff_swimlane: project_staff_swimlane,
      assigned_status_trigger: assigned_status_trigger,
      denied_pending_trigger: denied_pending_trigger
    )

    # Wiring unique beginning to shared loop
    start_event.connect_to!(initial_review_task)
    initial_review_task_gateway = CeWorkflowBuilder.create_gateway(template, 'initial_review_task')
    initial_review_task.connect_to!(initial_review_task_gateway)
    initial_review_task_gateway.connect_to!(loop_nodes[:admin_decline_gateway], condition: 'move_forward = 0')
    initial_review_task_gateway.connect_to!(initial_client_engagement_task)
    initial_client_engagement_task.connect_to!(client_engagement_task)
    client_engagement_gateway = CeWorkflowBuilder.create_gateway(template, 'client_engagement_task')
    client_engagement_task.connect_to!(client_engagement_gateway)
    client_engagement_gateway.connect_to!(loop_nodes[:admin_decline_gateway], condition: 'move_forward = 0')
    client_engagement_gateway.connect_to!(client_offer_outcome_task)
    client_offer_outcome_gateway = CeWorkflowBuilder.create_gateway(template, 'client_offer_outcome')
    client_offer_outcome_task.connect_to!(client_offer_outcome_gateway)
    client_offer_outcome_gateway.connect_to!(loop_nodes[:admin_decline_gateway], condition: 'move_forward = 0')
    client_offer_outcome_gateway.connect_to!(loop_nodes[:provider_outcome_1])

    template.validate!
    puts(template.to_mermaid_diagram)
    template
  end

  def build_admin_assign_workflow
    identifier = 'admin_assign_workflow'
    template_name = 'Admin Assign Workflow'
    form_ids = {
      initial_outgoing_referral: 'admin_assign_workflow_initial_outgoing_referral',
      provider_outcome_1: 'housing_workflow_provider_outcome_1',
      provider_outcome_2: 'housing_workflow_provider_outcome_2',
      provider_outcome_3: 'housing_workflow_provider_outcome_3',
      denial_review_1: 'housing_workflow_denial_review_1',
      denial_review_2: 'housing_workflow_denial_review_2',
      denial_review_3: 'housing_workflow_denial_review_3',
      confirm_success: 'housing_workflow_confirm_success',
    }
    CeWorkflowBuilder.delete_template_and_associated_data(identifier)
    template = CeWorkflowBuilder.create_template(identifier, template_name, @data_source)
    ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
    project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

    assigned_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'assigned', name: 'Assigned', data_source: @data_source
    )
    denied_pending_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'denial_pending', name: 'Denial Pending', data_source: @data_source
    )
    assigned_status_trigger = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': assigned_status.key }}]
    denied_pending_trigger = [{ event: 'enable_step', message: 'set_custom_referral_status', params: { 'custom_status_key': denied_pending_status.key }}]

    # Unique beginning
    start_event = CeWorkflowBuilder.create_start_event(template)
    initial_outgoing_referral_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Admin Assign',
      form_definition_identifier: form_ids[:initial_outgoing_referral],
      template: template,
      swimlane: ce_staff_swimlane,
      trigger_config: assigned_status_trigger,
    )
    create_ce_event_task = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Create CE Event',
      template_id: template.id,
      trigger_config: [{ event: 'complete_step', message: 'create_ce_event' }],
    )

    # Shared loop
    loop_nodes = build_provider_outcome_denial_review_loop(
      template: template,
      form_ids: form_ids,
      ce_staff_swimlane: ce_staff_swimlane,
      project_staff_swimlane: project_staff_swimlane,
      assigned_status_trigger: assigned_status_trigger,
      denied_pending_trigger: denied_pending_trigger
    )

    # Wiring unique beginning to shared loop
    start_event.connect_to!(initial_outgoing_referral_task)
    initial_outgoing_referral_task.connect_to!(create_ce_event_task)
    create_ce_event_task.connect_to!(loop_nodes[:provider_outcome_1])

    template.validate!
    puts(template.to_mermaid_diagram)
    template
  end

  private

  # Returns a hash of key nodes for wiring
  def build_provider_outcome_denial_review_loop(template:, form_ids:, ce_staff_swimlane:, project_staff_swimlane:, assigned_status_trigger:, denied_pending_trigger:)
    # Provider outcome tasks
    provider_outcome_1 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome',
      form_definition_identifier: form_ids[:provider_outcome_1],
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger,
    )
    provider_outcome_2 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome (Second Attempt)',
      form_definition_identifier: form_ids[:provider_outcome_2],
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger,
    )
    provider_outcome_3 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Outcome (Third Attempt)',
      form_definition_identifier: form_ids[:provider_outcome_3],
      template_id: template.id,
      swimlane: project_staff_swimlane,
      trigger_config: assigned_status_trigger,
    )

    # Script tasks
    provider_rejects_ce_event = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Update CE Event with result "Unsuccessful referral: provider rejected"',
      template_id: template.id,
      trigger_config: [{ event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '3' } }],
    )
    client_rejects_ce_event = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Update CE Event with result "Unsuccessful referral: client rejected"',
      template_id: template.id,
      trigger_config: [{ event: 'complete_step', message: 'set_ce_event_result', params: { referral_result: '2' } }],
    )
    create_enrollment = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Create Enrollment',
      template_id: template.id,
      trigger_config: [{ event: 'complete_step', message: 'create_enrollment' }],
    )

    # Denial review tasks
    denial_review_1 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review',
      form_definition_identifier: form_ids[:denial_review_1],
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger,
    )
    denial_review_2 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review (Second)',
      form_definition_identifier: form_ids[:denial_review_2],
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger,
    )
    denial_review_3 = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review (Third)',
      form_definition_identifier: form_ids[:denial_review_3],
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: denied_pending_trigger,
    )

    # Confirm success
    confirm_success = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Confirm Success',
      form_definition_identifier: form_ids[:confirm_success],
      template_id: template.id,
      swimlane: ce_staff_swimlane,
    )

    # Events
    accept_event = CeWorkflowBuilder.create_accept_event(template, update_ce_event: true)
    decline_event = CeWorkflowBuilder.create_decline_event(template)

    # Gateways
    admin_decline_gateway = CeWorkflowBuilder.create_gateway(template, 'admin_decline_gateway')
    admin_decline_gateway.connect_to!(client_rejects_ce_event, condition: 'referral_result = 2')
    admin_decline_gateway.connect_to!(provider_rejects_ce_event, condition: 'referral_result = 3')
    admin_decline_gateway.connect_to!(decline_event)
    client_rejects_ce_event.connect_to!(decline_event)
    provider_rejects_ce_event.connect_to!(decline_event)

    # Provider Outcome 1 => Gateway => Denial Review 1 OR Create Enrollment (Script)
    provider_outcome_gateway_1 = CeWorkflowBuilder.create_gateway(template, 'provider_outcome_1')
    provider_outcome_1.connect_to!(provider_outcome_gateway_1)
    provider_outcome_gateway_1.connect_to!(denial_review_1, condition: 'move_forward = 0')
    provider_outcome_gateway_1.connect_to!(create_enrollment)

    # Provider Outcome 2 => Gateway => Denial Review 2 OR Create Enrollment (Script)
    provider_outcome_gateway_2 = CeWorkflowBuilder.create_gateway(template, 'provider_outcome_2')
    provider_outcome_2.connect_to!(provider_outcome_gateway_2)
    provider_outcome_gateway_2.connect_to!(denial_review_2, condition: 'move_forward = 0')
    provider_outcome_gateway_2.connect_to!(create_enrollment)

    # Provider Outcome 3 => Gateway => Denial Review 3 OR Create Enrollment (Script)
    provider_outcome_gateway_3 = CeWorkflowBuilder.create_gateway(template, 'provider_outcome_3')
    provider_outcome_3.connect_to!(provider_outcome_gateway_3)
    provider_outcome_gateway_3.connect_to!(denial_review_3, condition: 'move_forward = 0')
    provider_outcome_gateway_3.connect_to!(create_enrollment)

    # Denial Review 1 => Gateway => Decline OR send back to Provider Outcome
    denial_review_gateway_1 = CeWorkflowBuilder.create_gateway(template, 'denial_review_1')
    denial_review_1.connect_to!(denial_review_gateway_1)
    denial_review_gateway_1.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1')
    denial_review_gateway_1.connect_to!(provider_outcome_2)

    # Denial Review 2 => Gateway => Decline OR send back to Provider Outcome
    denial_review_gateway_2 = CeWorkflowBuilder.create_gateway(template, 'denial_review_2')
    denial_review_2.connect_to!(denial_review_gateway_2)
    denial_review_gateway_2.connect_to!(admin_decline_gateway, condition: 'denial_review_decision = 1')
    denial_review_gateway_2.connect_to!(provider_outcome_3)

    # Denial Review 3 => Gateway => Decline (cannot send back)
    denial_review_3.connect_to!(admin_decline_gateway)

    # Create Enrollment (Script) => Confirm Success Task
    create_enrollment.connect_to!(confirm_success)

    # Confirm Success Task => Accept Event or Decline
    confirm_success.connect_to!(admin_decline_gateway, condition: 'move_forward = 0')
    confirm_success.connect_to!(accept_event, condition: 'move_forward = 1')

    {
      provider_outcome_1: provider_outcome_1,
      admin_decline_gateway: admin_decline_gateway
    }
  end
end