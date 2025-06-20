desc 'Script to create CE workflow definition'
# This task is for developing and iterating on CE workflow definitions.
# It will be run in staging/training environments until the workflows are ready, at which point we will run it in production.
# CAUTION: It deletes existing referrals and opportunities, so that we don't have to worry about definitions shifting underfoot.
# This means it should NOT be run in production after the first time!
# Usage: rails driver:hmis:ce_define_workflows
task ce_define_workflows: [:environment] do
  raise 'This task destroys data and should not be run in production!' if Rails.env.production?

  TEMPLATE_IDENTIFER = 'coordinated_entry_referral'

  GENERIC_YES_NO = 'generic_yes_no'
  FORM_DEFINITION_IDENTIFIERS = [GENERIC_YES_NO]

  puts "Deleting existing CE data associated with template #{TEMPLATE_IDENTIFER}"

  templates = Hmis::WorkflowDefinition::Template.where(identifier: TEMPLATE_IDENTIFER)
  opportunities = Hmis::Ce::Opportunity.where(workflow_template_identifier: TEMPLATE_IDENTIFER)
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

  Hmis::WorkflowDefinition::Swimlane.where(template: templates).destroy_all
  Hmis::WorkflowDefinition::Flow.where(template: templates).destroy_all
  Hmis::WorkflowDefinition::Node.where(template: templates).destroy_all
  templates.destroy_all

  # Temporarily disable the callback that prevents destroying published forms
  Hmis::Form::Definition.skip_callback(:destroy, :before, :can_be_destroyed)
  Hmis::Form::Definition.where(role: 'CE_REFERRAL_STEP', identifier: FORM_DEFINITION_IDENTIFIERS).destroy_all
  Hmis::Form::Definition.set_callback(:destroy, :before, :can_be_destroyed) # re-enable callback

  puts 'Enabling CE in AppConfigProperty'
  ce_enabled = AppConfigProperty.find_or_initialize_by(key: 'hmis_ce/enabled')
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  data_source = GrdaWarehouse::DataSource.hmis.sole
  puts "Creating workflow definition template for data source #{data_source.id}"

  template = Hmis::WorkflowDefinition::Template.create!(
    # TODO - discuss name and identifier
    identifier: 'coordinated_entry_referral',
    name: 'Standard Coordinated Entry Referral',
    data_source: data_source,
    template_type: 'ce_referral',
    status: 'published',
    version: 0,
  )

  ce_staff_swimlane = template.swimlanes.create!(name: 'CE Staff')
  project_staff_swimlane = template.swimlanes.create!(name: 'Project Staff')

  start_event = Hmis::WorkflowDefinition::StartEvent.create!(
    name: 'Start Referral',
    template: template,
    trigger_config: [
      {
        event: 'start_workflow',
        message: 'start_referral',
      },
    ]
  )

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

  review_task = Hmis::WorkflowDefinition::Task.create!(
    name: 'Review Individual or Household',
    form_definition_identifier: generic_yes_no_form.identifier,
    template: template,
    swimlane: ce_staff_swimlane,
  )

  project_offer_outcome_task = Hmis::WorkflowDefinition::Task.create!(
    name: 'Project Offer Outcome',
    form_definition_identifier: generic_yes_no_form.identifier,
    template_id: template.id,
    swimlane: project_staff_swimlane,
  )

  accept_event = Hmis::WorkflowDefinition::EndEvent.create!(
    name: 'Referral Accepted',
    template: template,
    trigger_config: [
      {
        event: 'end_workflow',
        message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
      },
      {
        event: 'end_workflow',
        message: 'create_enrollment',
      },
    ]
  )

  decline_event = Hmis::WorkflowDefinition::EndEvent.create!(
    name: 'Referral Declined',
    template: template,
    trigger_config: [
      {
        event: 'end_workflow',
        message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
      },
    ]
  )

  review_task_gateway = Hmis::WorkflowDefinition::Gateway.create!(
    template: template,
    gateway_type: 'exclusive',
    name: 'review_task_gateway'
  )

  project_offer_outcome_gateway = Hmis::WorkflowDefinition::Gateway.create!(
    template: template,
    gateway_type: 'exclusive',
    name: 'project_offer_outcome_gateway'
  )

  start_event.connect_to!(review_task)

  review_task.connect_to!(review_task_gateway)
  review_task_gateway.connect_to!(project_offer_outcome_task, condition: 'move_forward = 1')
  review_task_gateway.connect_to!(decline_event)

  project_offer_outcome_task.connect_to!(project_offer_outcome_gateway)
  project_offer_outcome_gateway.connect_to!(accept_event, condition: 'move_forward = 1')
  project_offer_outcome_gateway.connect_to!(decline_event)

  template.validate!

  puts(template.to_mermaid_diagram)
end
