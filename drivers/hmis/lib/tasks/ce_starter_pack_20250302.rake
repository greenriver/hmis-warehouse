# Helpers to reduce cruft and make the starter pack script more readable
def create_template(name, identifier)
  template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: identifier,
    status: 'published'
  )
  template.name = name
  template.version = 0
  template.save! if template.changed?
  template
end

def create_event(template, event, message)
  workflow_event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
    name: message,
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
    form_definition_id: definition.id,
    template_id: template.id,
  )
  task.name = name
  task.swimlane = swimlane
  task.save! if task.changed?
  task
end

def create_gateway(template, name)
  gateway = Hmis::WorkflowDefinition::Gateway.find_or_initialize_by(
    template: template,
    gateway_type: 'exclusive',
    name: name
  )
  gateway.save! if gateway.changed?
  gateway
end

desc 'Script to populate local dev databases with "starter-pack" CE records like templates, swimlanes, and tasks'
# Usage: rails driver:hmis:ce_starter_pack_20250302
task ce_starter_pack_20250302: [:environment] do
  puts "Enabling CE in AppConfigProperty"
  ce_enabled = AppConfigProperty.find_or_initialize_by(
    key: 'hmis_ce/enabled',
  )
  ce_enabled.value = true
  ce_enabled.save! if ce_enabled.changed?

  puts 'Creating a starter pack of task templates'

  puts '- Creating No Tasks template, a simple template with no tasks, just a start event and referral acceptance.'
  no_task_template = create_template('No Tasks', 'no_tasks')
  start_workflow_event = create_event(no_task_template, 'start_workflow', 'start_referral')
  accept_workflow_event = create_event(no_task_template, 'end_workflow', 'accept_referral')
  start_workflow_event.connect_to!(accept_workflow_event) unless start_workflow_event.outflows.where(target_node_id: accept_workflow_event.id).exists?

  puts '- Creating One Task template, another simple template that has 1 task, which can cause the referral to either succeed or fail.'
  one_task_template = create_template('One Task', 'one_task')
  case_managers = one_task_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  start_workflow_event = create_event(one_task_template, 'start_workflow', 'start_referral')
  accept_workflow_event = create_event(one_task_template, 'end_workflow', 'accept_referral')
  reject_workflow_event = create_event(one_task_template, 'end_workflow', 'reject_referral')

  client_accepts_form_def = Hmis::Form::Definition.find_or_initialize_by(
    identifier: 'confirm_client_accepts_referral',
    status: 'published'
  )
  client_accepts_form_def.title = 'Confirm Client Accepts Referral'
  client_accepts_form_def.role = 'CE_REFERRAL_STEP'
  client_accepts_form_def.version ||= 0
  client_accepts_form_def.definition = {
    "item": [
      {
        "text": "Date Contacted",
        "type": "DATE",
        "link_id": "date_contacted",
        "required": true,
        "read_only": false,
        "warn_if_empty": false,
        "disabled_display": "HIDDEN",
        "mapping": {"custom_field_key": "confirm_client_accepts_referral_date_contacted"}
      },
      {
        "text": "Client Accepts Referral",
        "type": "CHOICE",
        "link_id": "client_accepted",
        "required": true,
        "read_only": false,
        "warn_if_empty": false,
        "disabled_display": "HIDDEN",
        "pick_list_options": [
          {
            "code": "1",
            "label": "Yes, client accepts referral"
          },
          {
            "code": "0",
            "label": "No, client does not accept referral or could not be contacted"
          }
        ],
        "mapping": {"custom_field_key": "confirm_client_accepts_referral_client_accepted"}
      },
    ]
  }
  client_accepts_form_def.save! if client_accepts_form_def.changed?
  # TODO(#7414) - add CDEDs, so this is editable from the form builder

  client_acceptance_task = create_task(client_accepts_form_def, one_task_template,  'Confirm Client Accepts Referral', case_managers)
  gateway = create_gateway(one_task_template, 'client acceptance')

  start_workflow_event.connect_to!(client_acceptance_task) unless start_workflow_event.outflows.where(target_node_id: client_acceptance_task.id).exists?
  client_acceptance_task.connect_to!(gateway) unless client_acceptance_task.outflows.where(target_node_id: gateway.id).exists?
  gateway.connect_to!(reject_workflow_event, condition: 'client_accepted = 0') unless gateway.outflows.where(target_node_id: reject_workflow_event.id).exists?
  gateway.connect_to!(accept_workflow_event, condition: 'client_accepted = 1') unless gateway.outflows.where(target_node_id: accept_workflow_event.id).exists?

  puts '- Creating Admin Approve Denial template, a slightly more complicated template with multiple swimlanes.'
  # Start workflow -> Client Approval task (Case Manager) -> Client Approval Gateway...
  # -> Approved -> End Workflow with acceptance
  # -> Denied -> Admin Approval task (Admin) -> Admin Gateway...
  #    -> Approved -> End Workflow with denial
  #    -> Denied -> return to Client Approval task
  admin_approval_template = create_template('Admin Approve Denial', 'admin_approve_denial')
  case_managers = admin_approval_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  admins = admin_approval_template.swimlanes.find_or_create_by!(name: 'Admins')

  start_workflow_event = create_event(admin_approval_template, 'start_workflow', 'start_referral')
  accept_workflow_event = create_event(admin_approval_template, 'end_workflow', 'accept_referral')
  reject_workflow_event = create_event(admin_approval_template, 'end_workflow', 'reject_referral')

  client_acceptance_task = create_task(client_accepts_form_def, admin_approval_template,  'Confirm Client Accepts Referral', case_managers)

  review_denial_form_def = Hmis::Form::Definition.find_or_initialize_by(
    identifier: 'ce_admin_review_denial',
    status: 'published'
  )
  review_denial_form_def.title = 'Review Denial'
  review_denial_form_def.role = 'CE_REFERRAL_STEP'
  review_denial_form_def.version ||= 0
  review_denial_form_def.definition = {
    "item": [
      {
        "text": "Decision",
        "type": "CHOICE",
        "link_id": "review_denial_decision",
        "required": true,
        "read_only": false,
        "warn_if_empty": false,
        "disabled_display": "HIDDEN",
        "pick_list_options": [
          {
            "code": "1",
            "label": "Approve Denial"
          },
          {
            "code": "0",
            "label": "Send Back"
          }
        ],
        "mapping": {"custom_field_key": "ce_review_denial_decision"}
      },
    ]
  }
  review_denial_form_def.save! if review_denial_form_def.changed?

  admin_acceptance_task = create_task(review_denial_form_def, admin_approval_template,  'Review Denial', admins)
  client_acceptance_gateway = create_gateway(admin_approval_template, 'client acceptance')
  admin_review_gateway = create_gateway(admin_approval_template, 'admin review')

  start_workflow_event.connect_to!(client_acceptance_task) unless start_workflow_event.outflows.where(target_node_id: client_acceptance_task.id).exists?
  client_acceptance_task.connect_to!(client_acceptance_gateway) unless client_acceptance_task.outflows.where(target_node_id: client_acceptance_gateway.id).exists?
  client_acceptance_gateway.connect_to!(accept_workflow_event, condition: 'client_accepted = 1') unless client_acceptance_gateway.outflows.where(target_node_id: accept_workflow_event.id).exists?
  client_acceptance_gateway.connect_to!(admin_acceptance_task, condition: 'client_accepted = 0') unless client_acceptance_gateway.outflows.where(target_node_id: admin_acceptance_task.id).exists?
  admin_acceptance_task.connect_to!(admin_review_gateway) unless admin_acceptance_task.outflows.where(target_node_id: admin_review_gateway.id).exists?
  admin_review_gateway.connect_to!(client_acceptance_task, condition: 'review_denial_decision = 0') unless admin_review_gateway.outflows.where(target_node_id: client_acceptance_task.id).exists?
  admin_review_gateway.connect_to!(reject_workflow_event, condition: 'review_denial_decision = 1') unless admin_review_gateway.outflows.where(target_node_id: reject_workflow_event.id).exists?

  # Next, create a new organization and project to use for CE. This isn't strictly necessary -- devs will already have
  # orgs and projects in their local dbs they can use for testing -- but it's helpful for the sake of the starter pack
  # to have this script create a project/org whose existence it can rely on
  puts 'Creating CE Test Org and Ce Test Project'
  hmis_ds = GrdaWarehouse::DataSource.hmis.first
  system_user = Hmis::Hud::User.system_user(data_source_id: hmis_ds.id)
  ce_org = Hmis::Hud::Organization.find_or_initialize_by(
    data_source_id: hmis_ds.id,
    organization_name: 'CE Test Org',
  )
  ce_org.user = system_user
  ce_org.victim_service_provider = false
  ce_org.save! if ce_org.changed?

  ce_project = Hmis::Hud::Project.find_or_initialize_by(
    data_source_id: hmis_ds.id,
    project_name: 'CE Test Project',
  )
  ce_project.organization = ce_org
  ce_project.user ||= system_user
  ce_project.continuum_project ||= true
  ce_project.operating_start_date ||= 4.weeks.ago
  ce_project.project_type ||= 3
  ce_project.save! if ce_project.changed?

  # Set up match rules in this project
  puts 'Creating match rules'
  ce_match_rule = Hmis::Ce::Match::Rule.find_or_initialize_by(
    name: 'Over 18',
    owner: ce_project,
  )
  ce_match_rule.rule_type = 'eligibility_requirement'
  ce_match_rule.expression = 'current_age >= 18'
  ce_match_rule.applicability_config ||= {}
  ce_match_rule.save! if ce_match_rule.changed?

  # Create candidates for opportunities. First create some opportunities using the frontend
  puts 'Building a candidate pool'
  Hmis::Ce::Match::CandidatePoolBuilder.new.perform

  puts 'Running the CE match engine'
  clients = Hmis::Hud::Client.hmis.limit(100) # modify this if you want to include different or specific clients
  Hmis::Ce::Match::CandidatePool.all.each do |pool|
    Hmis::Ce::Match::Engine.call(pool, clients)
  end
end
