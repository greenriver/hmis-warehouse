# This task is for developing and iterating on CE workflow definitions.
# It will be run in staging/training environments until the workflows are ready, at which point we will run it in production.
# CAUTION: It deletes existing referrals and opportunities, so that we don't have to worry about definitions shifting underfoot.
# This means it should NOT be run in production after the first time!
# Usage: rails driver:hmis:ce_define_workflows

module CeWorkflowBuilder
  COORDINATED_ENTRY_TEMPLATE = 'coordinated_entry_referral'
  GENERIC_YES_NO = 'generic_yes_no'

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
      ]
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
          [
            {
              event: 'end_workflow',
              message: 'create_enrollment',
            },
          ] if create_enrollment
        )
      ].compact
    )
  end

  def self.create_gateway(template, name, gateway_type: 'exclusive')
    Hmis::WorkflowDefinition::Gateway.create!(
      template: template,
      gateway_type: gateway_type,
      name: "gw_#{gateway_type}_#{name}"
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
      ]
    )
  end

  def self.create_basic_ce_template(data_source)
    delete_template_and_associated_data(COORDINATED_ENTRY_TEMPLATE)
    delete_form_definitions([GENERIC_YES_NO])

    puts "Creating workflow definition template #{COORDINATED_ENTRY_TEMPLATE}"

    # TODO - revisit the name and identifier, it should be more specific
    template = create_template(COORDINATED_ENTRY_TEMPLATE, 'Standard Coordinated Entry Referral', data_source)

    ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
    project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

    start_event = create_start_event(template)

    # Generic form that can be used for many steps. Collects date, notes, and yes/no question
    # TODO - Update all of this, it's just proof of concept
    generic_yes_no_form = Hmis::Form::Definition.create!(
      identifier: GENERIC_YES_NO,
      status: 'published',
      title: 'Generic Yes/No Form',
      role: 'CE_REFERRAL_STEP',
      version: 0,
      definition: {
        "item": [
          {
            "text": "Date",
            "type": "DATE",
            "link_id": "date",
            "required": true,
            "mapping": {"custom_field_key": "ce_generic_date"},
          },
          {
            "text": "Notes",
            "type": "TEXT",
            "link_id": "notes",
            "required": false,
            "mapping": {"custom_field_key": "ce_generic_notes"}
          },
          {
            "text": "Move forward?",
            "type": "CHOICE",
            "link_id": "move_forward",
            "required": true,
            "pick_list_options": [
              {
                "code": "1",
                "label": "Yes, move forward"
              },
              {
                "code": "0",
                "label": "No, decline referral"
              }
            ],
            "mapping": {"custom_field_key": "ce_generic_move_forward"}
          },
        ]
      }
    )

    review_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Review Individual or Household',
      form_definition_identifier: generic_yes_no_form.identifier,
      template: template,
      swimlane: ce_staff_swimlane,
    )

    project_offer_outcome_task = Hmis::WorkflowDefinition::UserTask.create!(
      name: 'Project Offer Outcome',
      form_definition_identifier: generic_yes_no_form.identifier,
      template_id: template.id,
      swimlane: project_staff_swimlane,
    )

    create_enrollment_task = Hmis::WorkflowDefinition::ScriptTask.create!(
      name: 'Create Enrollment Script Task',
      template_id: template.id,
      trigger_config: [
        {
          event: 'complete_step',
          message: 'create_enrollment',
        },
      ]
    )

    accept_event = create_accept_event(template)
    decline_event = create_decline_event(template)

    review_task_gateway = create_gateway(template, 'review_task')
    project_offer_outcome_gateway = create_gateway(template, 'project_offer_outcome')

    start_event.connect_to!(review_task)

    review_task.connect_to!(review_task_gateway)
    review_task_gateway.connect_to!(project_offer_outcome_task, condition: 'move_forward = 1')
    review_task_gateway.connect_to!(decline_event)

    project_offer_outcome_task.connect_to!(project_offer_outcome_gateway)
    project_offer_outcome_gateway.connect_to!(create_enrollment_task, condition: 'move_forward = 1')
    project_offer_outcome_gateway.connect_to!(decline_event)

    create_enrollment_task.connect_to!(accept_event)

    template.validate!

    puts(template.to_mermaid_diagram)

    template
  end
end

desc 'Script to create CE workflow definition'
task ce_define_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  data_source = GrdaWarehouse::DataSource.hmis.sole

  # Just putting this here for convenience. It can be removed after everyone has run it once
  puts 'Fixing polymorphic type for WFD Nodes'
  Hmis::WorkflowDefinition::Node.where(type: 'Hmis::WorkflowDefinition::Task').update_all(type: 'Hmis::WorkflowDefinition::UserTask')

  puts "Creating workflow templates in data source #{data_source.id} (#{data_source.name})"
  CeWorkflowBuilder.create_basic_ce_template(data_source)

  # define more functions in Hmis::Ce::WorkflowBuilder and call them here to create additional templates, like:
  # Hmis::Ce::WorkflowBuilder.create_xyz_template(data_source)
end
