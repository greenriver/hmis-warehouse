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

  def self.create_state_machine_custom_statuses(data_source)
    puts "Creating custom statuses for state machine statuses"

    # Create custom statuses for each state machine status.
    # This allows us to return only custom statuses in the picklist, avoiding key collisions.
    state_machine_statuses = Hmis::Ce::Referral.state_machine_states.map do |status|
      { key: status.to_s, name: status.to_s.humanize.titleize }
    end

    state_machine_statuses.each do |status_config|
      Hmis::Ce::CustomReferralStatus.find_or_create_by!(
        key: status_config[:key],
        data_source: data_source,
      ) do |status|
        status.name = status_config[:name]
      end
    end
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

  def self.create_accept_event(template, create_enrollment: false)
    Hmis::WorkflowDefinition::EndEvent.create!(
      name: 'Referral Accepted',
      template: template,
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
        },
        *(
          if create_enrollment
            [
              {
                event: 'end_workflow',
                message: 'create_enrollment',
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

  def self.create_step_form(identifier:, definition:, title: nil)
    form_def = Hmis::Form::Definition.new(
      identifier: identifier,
      status: :published,
      title: title || identifier.titleize,
      role: :CE_REFERRAL_STEP,
      version: 0,
      definition: definition,
    )
    raise 'Form definition must be present' if definition.blank?

    errors = Hmis::Form::DefinitionValidator.perform(definition, form_def.role, skip_cded_validation: true)
    raise "Form definition #{form_def.identifier} is not valid: #{errors.map(&:full_message)}" if errors.any?

    form_def.save!
    form_def
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
    initial_review_task_form_identifier = 'ac_workflow_v1_initial_review_task'
    ce_offer_task_form_identifier = 'ac_workflow_v1_ce_offer_task'
    project_offer_task_form_identifier = 'ac_workflow_v1_project_offer_task'
    denial_review_form_identifier = 'ac_workflow_v1_denial_review_task'
    confirm_success_task_form_identifier = 'ac_workflow_v1_confirm_success_task'

    delete_form_definitions([
                              initial_review_task_form_identifier,
                              ce_offer_task_form_identifier,
                              project_offer_task_form_identifier,
                              denial_review_form_identifier,
                              confirm_success_task_form_identifier,
                            ])

    puts "Creating workflow definition template '#{identifier}'"

    template = create_template(identifier, template_name, data_source)

    # Create Swimlanes
    ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
    project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

    start_event = create_start_event(template)

    # Form that is shared across several CE Staff tasks
    ce_staff_shared_form = {
      "item": [
        {
          "text": 'Date',
          "type": 'DATE',
          "link_id": 'date',
          "required": true,
          "mapping": { "custom_field_key": 'ce_task_date' },
        },
        {
          "text": 'Notes',
          "type": 'TEXT',
          "link_id": 'notes',
          "required": false,
          "mapping": { "custom_field_key": 'ce_task_notes' },
        },
        {
          "text": 'Continue with Referral?',
          "type": 'CHOICE',
          "link_id": 'move_forward',
          "required": true,
          "pick_list_options": [
            {
              "code": '1',
              "label": 'Yes, continue',
            },
            {
              "code": '0',
              "label": 'No, decline referral',
            },
          ],
          "mapping": { "custom_field_key": 'ce_generic_move_forward' },
        },
        {
          "text": 'Decline Reason',
          "type": 'CHOICE',
          "link_id": 'admin_decline_reason',
          "required": true,
          "pick_list_options": [
            { "code": 'HMIS user error' },
            { "code": 'Client needs to be reassessed' },
            { "code": 'Does not meet eligibility criteria' },
            { "code": 'No longer interested in this program' },
            { "code": 'No longer experiencing homelessness' },
            { "code": 'Vacancy no longer available' },
          ],
          "mapping": { "custom_field_key": 'ac_workflow_v1_admin_decline_reason' },
          "enable_behavior": 'ALL',
          "enable_when": [{ "question": 'move_forward', "operator": 'EQUAL', "answer_code": '0' }],
        },
      ],
    }

    create_step_form(
      identifier: initial_review_task_form_identifier,
      definition: ce_staff_shared_form,
    )
    create_step_form(
      identifier: ce_offer_task_form_identifier,
      definition: ce_staff_shared_form,
    )
    create_step_form(
      identifier: project_offer_task_form_identifier,
      definition: {
        "item": [
          {
            "text": 'Date',
            "type": 'DATE',
            "link_id": 'date',
            "required": true,
            "mapping": { "custom_field_key": 'ce_generic_date' },
          },
          {
            "text": 'Notes',
            "type": 'TEXT',
            "link_id": 'notes',
            "required": false,
            "mapping": { "custom_field_key": 'ce_generic_notes' },
          },
          {
            "text": 'Decision',
            "type": 'CHOICE',
            "link_id": 'move_forward',
            "required": true,
            "component": 'RADIO_BUTTONS',
            "pick_list_options": [
              {
                "code": '1',
                "label": 'Accept - Enroll in Project',
              },
              {
                "code": '0',
                "label": 'Decline - Submit Referral for Denial Review',
              },
            ],
            "mapping": { "custom_field_key": 'ce_generic_move_forward' },
          },
          {
            "text": 'Decline Reason',
            "type": 'CHOICE',
            "link_id": 'denial_reason',
            "required": true,
            "component": 'RADIO_BUTTONS',
            "pick_list_options": [
              { "code": 'HMIS user error' },
              { "code": 'Inability to complete intake' },
              { "code": 'Does not meet eligibility criteria' },
              { "code": 'No longer interested in this program' },
              { "code": 'No longer experiencing homelessness' },
              { "code": 'Estimated vacancy no longer available' },
              { "code": 'Enrolled, but declined HMIS data entry' },
            ],
            "mapping": { "custom_field_key": 'ac_workflow_v1_provider_denial_reason' },
            "enable_behavior": 'ALL',
            "enable_when": [{ "question": 'move_forward', "operator": 'EQUAL', "answer_code": '0' }],
          },
          {
            "text": 'The client will be enrolled in the project when this form is submitted.',
            "type": 'DISPLAY',
            "component": 'ALERT_INFO',
            "link_id": 'enroll_message',
            "enable_behavior": 'ALL',
            "enable_when": [{ "question": 'move_forward', "operator": 'EQUAL', "answer_code": '1' }],
          },
        ],
      },
    )

    create_step_form(
      identifier: denial_review_form_identifier,
      definition: {
        "item": [
          {
            "text": 'Date',
            "type": 'DATE',
            "link_id": 'date',
            "required": true,
            "mapping": { "custom_field_key": 'ce_generic_date' },
          },
          {
            "text": 'Notes',
            "type": 'TEXT',
            "link_id": 'notes',
            "required": false,
            "mapping": { "custom_field_key": 'ce_generic_notes' },
          },
          {
            "text": 'Decision',
            "type": 'CHOICE',
            "link_id": 'ac_workflow_v1_denial_review_decision',
            "required": true,
            "component": 'RADIO_BUTTONS',
            "pick_list_options": [
              {
                "code": '1',
                "label": 'Approve Denial',
              },
              {
                "code": '0',
                "label": 'Send Back',
              },
            ],
            "mapping": { "custom_field_key": 'ac_workflow_v1_denial_review_decision' },
          },
          {
            "text": 'Reason for Sending Back',
            "type": 'CHOICE',
            "link_id": 'denial_reason',
            "component": 'RADIO_BUTTONS',
            "required": false,
            "pick_list_options": [
              { "code": 'HMIS user error' },
              { "code": 'Client should be eligible' },
            ],
            "mapping": { "custom_field_key": 'ac_workflow_v1_denial_review_reason' },
            "enable_behavior": 'ALL',
            "enable_when": [{ "question": 'denial_review_decision', "operator": 'EQUAL', "answer_code": '0' }],
          },
        ],
      },
    )
    create_step_form(
      identifier: confirm_success_task_form_identifier,
      definition: {
        "item": [
          {
            "text": 'Date',
            "type": 'DATE',
            "link_id": 'date',
            "required": true,
            "mapping": { "custom_field_key": 'ce_generic_date' },
          },
          {
            "text": 'Notes',
            "type": 'TEXT',
            "link_id": 'notes',
            "required": false,
            "mapping": { "custom_field_key": 'ce_generic_notes' },
          },
          {
            "text": 'Decision',
            "type": 'CHOICE',
            "link_id": 'move_forward',
            "required": true,
            "component": 'RADIO_BUTTONS',
            "pick_list_options": [
              {
                "code": '1',
                "label": 'Confirm - Individual or Household Successfully Enrolled',
              },
              {
                "code": '0',
                "label": 'Decline Referral',
              },
            ],
            "mapping": { "custom_field_key": 'ce_generic_move_forward' },
          },
          {
            "text": 'Decline Reason',
            "type": 'CHOICE',
            "link_id": 'admin_decline_reason',
            "required": true,
            "pick_list_options": [
              { "code": 'HMIS user error' },
              { "code": 'Client needs to be reassessed' },
              { "code": 'Does not meet eligibility criteria' },
              { "code": 'No longer interested in this program' },
              { "code": 'No longer experiencing homelessness' },
              { "code": 'Vacancy no longer available' },
            ],
            "component": 'RADIO_BUTTONS',
            "mapping": { "custom_field_key": 'ac_workflow_v1_admin_decline_reason_2' },
            "enable_behavior": 'ALL',
            "enable_when": [{ "question": 'move_forward', "operator": 'EQUAL', "answer_code": '0' }],
          },
        ],
      },
    )

    initial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Initial Review',
      form_definition_identifier: initial_review_task_form_identifier,
      template: template,
      swimlane: ce_staff_swimlane,
    )

    ce_make_offer_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Client Acceptance',
      form_definition_identifier: ce_offer_task_form_identifier,
      template_id: template.id,
      swimlane: ce_staff_swimlane,
    )

    project_offer_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Provider Acceptance',
      form_definition_identifier: project_offer_task_form_identifier,
      template_id: template.id,
      swimlane: project_staff_swimlane,
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

    denied_pending_status = Hmis::Ce::CustomReferralStatus.find_or_create_by!(
      key: 'denied_pending',
      name: 'Denied Pending',
      data_source: data_source,
    )

    denial_review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Denial Review',
      form_definition_identifier: denial_review_form_identifier,
      template_id: template.id,
      swimlane: ce_staff_swimlane,
      trigger_config: [
        {
          event: 'make_step_available',
          message: 'set_custom_referral_status',
          params: { 'custom_status_key': denied_pending_status.key },
        },
      ],
    )

    confirm_success_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Confirm Success',
      form_definition_identifier: confirm_success_task_form_identifier,
      template_id: template.id,
      swimlane: ce_staff_swimlane,
    )

    accept_event = create_accept_event(template)
    decline_event = create_decline_event(template)

    initial_review_task_gateway = create_gateway(template, 'initial_review_task')
    ce_offer_outcome_gateway = create_gateway(template, 'ce_offer_outcome')
    project_offer_outcome_gateway = create_gateway(template, 'project_offer_outcome')
    denial_review_gateway = create_gateway(template, 'denial_review')

    start_event.connect_to!(initial_review_task)

    # Initial Review => Gateway
    initial_review_task.connect_to!(initial_review_task_gateway)
    # Initial Review Gateway => CE Make Offer Task OR Decline Event.
    # Exclusive Gateway, so only the first outflow that matches condition is followed.
    initial_review_task_gateway.connect_to!(decline_event, condition: 'move_forward = 0')
    initial_review_task_gateway.connect_to!(ce_make_offer_task) # default outflow, so it appears under "unavailable tasks"

    # CE Make Offer Task => CE Offer Outcome Gateway
    ce_make_offer_task.connect_to!(ce_offer_outcome_gateway)
    # CE Offer Outcome Gateway => Project Offer Task OR Decline Event
    # Exclusive Gateway, so only the first outflow that matches condition is followed.
    ce_offer_outcome_gateway.connect_to!(decline_event, condition: 'move_forward = 0')
    ce_offer_outcome_gateway.connect_to!(project_offer_task) # default outflow, so it appears under "unavailable tasks"

    # Project Offer Task => Project Offer Outcome Gateway
    project_offer_task.connect_to!(project_offer_outcome_gateway)
    # Project Offer Outcome Gateway => Accept Event OR Create Enrollment Task
    # Exclusive Gateway, so only the first outflow that matches condition is followed.
    project_offer_outcome_gateway.connect_to!(denial_review_task, condition: 'move_forward = 0')
    project_offer_outcome_gateway.connect_to!(create_enrollment_task)
    # Create Enrollment Task => Confirm Success Task
    create_enrollment_task.connect_to!(confirm_success_task)

    # Denial Review Task => Denial Review Gateway
    denial_review_task.connect_to!(denial_review_gateway)
    # Denial Review Gateway => Decline OR Send Back to Project Offer Task
    # Exclusive Gateway, so only the first outflow that matches condition is followed.
    denial_review_gateway.connect_to!(decline_event, condition: 'ac_workflow_v1_denial_review_decision = 1') # Accept Denial
    denial_review_gateway.connect_to!(project_offer_task) # Send back. We make this the default task, so that the project offer task doesn't get hidden in the Available Tasks UI due to its conditional inflows...

    # Confirm Success Task => Accept Event
    confirm_success_task.connect_to!(decline_event, condition: 'move_forward = 0')
    confirm_success_task.connect_to!(accept_event)

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

  data_source = GrdaWarehouse::DataSource.hmis.sole

  CeWorkflowBuilder.create_state_machine_custom_statuses(data_source)

  puts "Creating workflow templates in data source #{data_source.id} (#{data_source.name})"
  CeWorkflowBuilder.build_housing_workflow_v1(data_source)

  # define more functions in Hmis::Ce::WorkflowBuilder and call them here to create additional templates, like:
  # Hmis::Ce::WorkflowBuilder.create_xyz_template(data_source)
end
