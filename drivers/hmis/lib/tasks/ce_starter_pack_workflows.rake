# Helpers to reduce cruft and make the starter pack script more readable
def create_template(name, identifier)
  template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: identifier,
    status: 'published',
  )
  template.template_type = 'ce_referral'
  template.name = name
  template.version = 0
  template.data_source = GrdaWarehouse::DataSource.hmis.first
  template.save! if template.changed?
  template
end

def create_start_event(*args)
  create_event(Hmis::WorkflowDefinition::StartEvent, *args)
end

def create_end_event(*args)
  create_event(Hmis::WorkflowDefinition::EndEvent, *args)
end

def create_event(klass, template, name, event, message)
  workflow_event = klass.find_or_initialize_by(
    name: name,
    template_id: template.id,
  )
  workflow_event.trigger_config = [
    {
      event: event,
      message: message,
    },
  ]
  workflow_event.save! if workflow_event.changed?
  workflow_event
end

def create_task(definition, template, name, swimlane)
  task = Hmis::WorkflowDefinition::Task.find_or_initialize_by(
    # form_definition_identifier: definition.identifier,
    template_id: template.id,
    name: name,
  )
  task.form_definition_identifier = definition.identifier
  task.swimlane = swimlane
  task.save! if task.changed?
  task
end

def create_gateway(template, name)
  gateway = Hmis::WorkflowDefinition::Gateway.find_or_initialize_by(
    template: template,
    gateway_type: 'exclusive',
    name: name,
  )
  gateway.save! if gateway.changed?
  gateway
end

def create_or_update_step_form(identifier, definition)
  form_def = Hmis::Form::Definition.find_or_initialize_by(
    identifier: identifier,
    status: :published,
  )
  form_def.title = identifier.titleize
  form_def.role = :CE_REFERRAL_STEP
  form_def.version ||= 0
  # binding.pry
  form_def.definition = definition
  errors = Hmis::Form::DefinitionValidator.perform(definition, form_def.role, skip_cded_validation: true)
  raise "Form definition #{form_def.identifier} is not valid: #{errors.map(&:full_message)}" if errors.any?

  form_def.save! if form_def.changed?
  form_def
end

confirm_proceed_and_denial_reason_items = [
  {
    "text": 'Review Decision',
    "type": 'CHOICE',
    "link_id": 'review_decision',
    "required": true,
    "mapping": {
      "custom_field_key": 'abc_review_decision',
    },
    "disabled_display": 'HIDDEN',
    "pick_list_options": [
      {
        "code": '1',
        "label": 'Proceed with referral',
      },
      {
        "code": '0',
        "label": 'Decline referral',
      },
    ],
  },
  {
    "text": 'Reason to decline this referral',
    "type": 'CHOICE',
    "required": true,
    "link_id": 'reason_to_decline_this_referral',
    "mapping": {
      "custom_field_key": 'abc_reason_to_decline_this_referral',
    },
    "component": 'RADIO_BUTTONS',
    "enable_when": [
      {
        "operator": 'EQUAL',
        "question": 'review_decision',
        "answer_code": '0',
      },
    ],
    "enable_behavior": 'ALL',
    "disabled_display": 'HIDDEN',
    "pick_list_options": [
      {
        "code": 'Client has another housing option',
      },
      {
        "code": "Client won't be eligible based on funding source",
      },
      {
        "code": "Client won't be eligible for housing type",
      },
      {
        "code": "Client won't be eligible for services",
      },
      {
        "code": 'Other',
      },
    ],
  },
]

# form with notes and proceed/decline with reasons
review_form = {
  "item": [
    {
      "text": 'Notes',
      "type": 'TEXT',
      "link_id": 'notes',
      "required": true,
      "mapping": {
        "custom_field_key": 'abc_referral_notes',
      },
      "disabled_display": 'HIDDEN',
    },
    *confirm_proceed_and_denial_reason_items.map(&:deep_stringify_keys),
  ],
}.deep_stringify_keys

# form with notes and client confirmation
client_contact_form = {
  "item": [
    {
      "text": 'Notes',
      "type": 'TEXT',
      "link_id": 'notes',
      "required": true,
      "mapping": {
        "custom_field_key": 'abc_referral_notes',
      },
      "disabled_display": 'HIDDEN',
    },
    {
      "text": 'Client has spoken to a shelter case manager and understands the services attached and the program requirements.',
      "type": 'CHOICE',
      "required": true,
      "link_id": 'client_contacted',
      "mapping": {
        "custom_field_key": 'stu_client_contacted',
      },
      "disabled_display": 'HIDDEN',
      "pick_list_options": [
        {
          "code": '1',
          "label": 'Yes',
        },
        {
          "code": '0',
          "label": 'No',
        },
      ],
    },
    *confirm_proceed_and_denial_reason_items.map(&:deep_stringify_keys),
  ],
}.deep_stringify_keys

# Form containing: Note, proceed/decline with reasons, text explaining that client will be enrolled in the project
enroll_client_msg_form = {
  "item": [
    {
      "text": 'Notes',
      "type": 'TEXT',
      "link_id": 'notes',
      "required": true,
      "mapping": {
        "custom_field_key": 'abc_referral_notes',
      },
      "disabled_display": 'HIDDEN',
    },
    *confirm_proceed_and_denial_reason_items.map(&:deep_stringify_keys),
    {
      "text": '<b>NOTE:</b> When you submit this task, the client will be enrolled in the project.',
      "type": 'DISPLAY',
      "link_id": 'enrollment_msg',
      "enable_when": [
        {
          "operator": 'EQUAL',
          "question": 'review_decision',
          "answer_code": '1',
        },
      ],
      "enable_behavior": 'ALL',
    },
  ],
}.deep_stringify_keys

task ce_build_match_route_four: [:environment] do
  raise 'CE not enabled' unless Hmis::Ce.configuration.enabled?

  puts '- Creating Second Sequential template, a template with non-conditional tasks that are executed sequentially.'
  Hmis::Hud::Base.transaction do
    template = create_template('Demo Workflow', 'ph_match_route_four_2')

    # Create swimlanes
    ce_staff = template.swimlanes.find_or_create_by!(name: 'CE Staff')
    shelter_agency = template.swimlanes.find_or_create_by!(name: 'Shelter Agency')
    housing_case_manager = template.swimlanes.find_or_create_by!(name: 'Housing Case Manager')

    # Create start and end events
    start_workflow_event = create_start_event(template, 'start referral', 'start_workflow', 'start_referral')
    accept_workflow_event = create_end_event(template, 'accept referral', 'end_workflow', 'accept_referral')
    reject_workflow_event = create_end_event(template, 'reject referral', 'end_workflow', 'reject_referral')

    # Forms
    # Form containing: Note, proceed/decline with reasons
    basic_review_form = create_or_update_step_form(template.identifier + '_basic_review', review_form)
    # Form containing: Note, client contact question, proceed/decline with reasons
    client_contacted_form = create_or_update_step_form(template.identifier + '_client_contacted', client_contact_form)
    # Form containing: Note, proceed/decline with reasons, text explaining that client will be enrolled in the project
    enroll_client_form = create_or_update_step_form(template.identifier + '_enroll_client', enroll_client_msg_form)

    # Task 1: Initial Review
    task_1 = create_task(basic_review_form, template, 'Initial Review', ce_staff)
    # Task 2: Shelter Agency Initial Review
    task_2 = create_task(client_contacted_form, template, 'Shelter Agency Initial Review', shelter_agency)
    # Task 3: Housing Case Manager Initial Review
    task_3 = create_task(basic_review_form, template, 'Housing Case Manager Initial Review', housing_case_manager)
    # Task 4: Housing Case Manager Review Match (TRIGGERS ENROLLMENT)
    task_4 = create_task(enroll_client_form, template, 'Housing Case Manager Review Referral', housing_case_manager)
    # TODO! fix this so it only triggers enrollment IF the review decision is to proceed with the referral. trigger config should support having a condition I think, otherwise we need to put it on a gateway?
    task_4.update!(trigger_config: [
      {
        event: 'complete_step',
        message: 'create_enrollment',
      },
    ])

    # Task 5: Indicate Move-in Date
    task_5 = create_task(basic_review_form, template, 'Indicate Move-in Date', housing_case_manager)
    # task_5.trigger_config = [
    #   {
    #     event: 'complete_step',
    #     message: 'set_move_in_date',
    #   }
    # ]
    # Task 6: Confirm Match Success
    task_6 = create_task(basic_review_form, template, 'Confirm Referral Success', ce_staff)

    # Add outflows for declining referral from each task. These all use the same condition because they all use the same form item for declining.
    # Create a new Gateway to represent declining the referral
    decline_gateway = create_gateway(template, 'Decline referral')
    decline_gateway.inflows.destroy_all # Remove any inflows
    decline_gateway.outflows.destroy_all # Remove any inflows
    # Connect the Gateway to the reject workflow event
    decline_gateway.connect_to!(reject_workflow_event)
    # All of these tasks can be connected to the decline gateway, since they all have the "Review decision" item in their forms
    [task_1, task_2, task_3, task_4, task_5, task_6].each do |task|
      # Remove other outflows from task
      task.outflows.destroy_all
      # Connect the task to the decline gateway conditionally
      task.connect_to!(decline_gateway, condition: 'review_decision = 0')
    end

      # Connect Start=> Task 1
    start_workflow_event.outflows.destroy_all
    start_workflow_event.connect_to!(task_1)

    # Connect tasks sequentially
    task_1.connect_to!(task_2)
    task_2.connect_to!(task_3)
    task_3.connect_to!(task_4)
    task_4.connect_to!(task_5)
    task_5.connect_to!(task_6)

    # Only the last task (Task 6) connects to the accept workflow event
    task_6.connect_to!(accept_workflow_event)

    puts "---- TEMPLATE DESCRIPTION: #{template.name} (#{template.identifier}) ----"
    # puts template.nodes.map(&:describe).join("\n")
    template.validate!
  end
end
