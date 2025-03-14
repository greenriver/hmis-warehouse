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
  # Create a starter pack of task templates
  # First, a simple template that doesn't have any tasks - just a start event and referral acceptance
  no_task_template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: 'no_tasks',
    status: 'published'
  )
  no_task_template.name = 'No Tasks'
  no_task_template.version = 0
  no_task_template.save! if no_task_template.changed?

  start_workflow_event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
    name: 'start referral',
    template_id: no_task_template.id,
  )
  start_workflow_event.trigger_config = [
    {
      event: 'start_workflow',
      message: 'start_referral',
    },
  ]
  start_workflow_event.save!

  accept_workflow_event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
    name: 'accept referral',
    template_id: no_task_template.id,
  )
  accept_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'accept_referral',
    },
  ]
  accept_workflow_event.save!

  start_workflow_event.connect_to!(accept_workflow_event) unless start_workflow_event.outflows.where(target_node_id: accept_workflow_event.id).exists?

  # Another very simple template that only has 1 task, which can cause the referral to either succeed or fail
  one_task_template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: 'one_task',
    status: 'published'
  )
  one_task_template.name = 'One Task'
  one_task_template.version = 0
  one_task_template.save! if one_task_template.changed?
  case_managers = one_task_template.swimlanes.find_or_create_by!(name: 'Case Managers')

  start_workflow_event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
    name: 'start referral',
    template_id: one_task_template.id,
  )
  start_workflow_event.swimlane_id = case_managers.id
  start_workflow_event.trigger_config = [
    {
      event: 'start_workflow',
      message: 'start_referral',
    },
  ]
  start_workflow_event.save!

  accept_workflow_event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
    name: 'accept referral',
    template_id: one_task_template.id,
  )
  accept_workflow_event.swimlane_id = case_managers.id
  accept_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'accept_referral',
    },
  ]
  accept_workflow_event.save!

  reject_workflow_event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
    name: 'reject referral',
    template_id: one_task_template.id,
  )
  reject_workflow_event.swimlane_id = case_managers.id
  reject_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'reject_referral',
    },
  ]
  reject_workflow_event.save!

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
        "mapping": {"custom_field_key": "ce_one_task_date_contacted"}
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
        "mapping": {"custom_field_key": "ce_one_task_client_accepted"}
      },
      {
        "text": "If you submit, the referral will be stopped and sent to an Admin for review. This cannot be undone.",
        "type": "DISPLAY",
        "link_id": "stop_referral_if_you_submit_the_referral",
        "component": "ALERT_ERROR",
        "enable_when": [
          {
            "operator": "EQUAL",
            "question": "client_accepted",
            "answer_code": "0"
          }
        ],
        "enable_behavior": "ALL",
        "disabled_display": "HIDDEN"
      },
      {
        "text": "Notes",
        "type": "TEXT",
        "link_id": "notes",
        "disabled_display": "HIDDEN",
        "mapping": {"custom_field_key": "ce_one_task_notes"}
      }
    ]
  }
  client_accepts_form_def.save! if client_accepts_form_def.changed?
  # TODO(#7414) - add CDEDs, so this is editable from the form builder

  client_acceptance_task = Hmis::WorkflowDefinition::Task.find_or_initialize_by(
    form_definition_id: client_accepts_form_def.id,
    template_id: one_task_template.id,
  )
  client_acceptance_task.name = 'Confirm Client Accepts Referral'
  client_acceptance_task.swimlane = case_managers
  client_acceptance_task.save! if client_acceptance_task.changed?

  gateway = Hmis::WorkflowDefinition::Gateway.find_or_initialize_by(
    template: one_task_template,
    gateway_type: 'exclusive',
    name: 'client acceptance'
  )
  start_workflow_event.connect_to!(client_acceptance_task) unless start_workflow_event.outflows.where(target_node_id: client_acceptance_task.id).exists?
  client_acceptance_task.connect_to!(gateway) unless client_acceptance_task.outflows.where(target_node_id: gateway.id).exists?
  gateway.connect_to!(reject_workflow_event, condition: 'client_accepted = 0') unless gateway.outflows.where(target_node_id: reject_workflow_event.id).exists?
  gateway.connect_to!(accept_workflow_event, condition: 'client_accepted = 1') unless gateway.outflows.where(target_node_id: accept_workflow_event.id).exists?

  # A slightly more complicated template with multiple swimlanes. Looks like:
  # Start workflow -> Client Approval task (Case Manager) -> Client Approval Gateway...
  # -> Approved -> End Workflow with acceptance
  # -> Denied -> Admin Approval task (Admin) -> Admin Gateway...
  #    -> Approved -> End Workflow with denial
  #    -> Denied -> return to Client Approval task
  admin_approval_template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: 'admin_approve_denial',
    status: 'published'
  )
  admin_approval_template.name = 'Admin Approve Denial'
  admin_approval_template.version = 0
  admin_approval_template.save! if admin_approval_template.changed?
  case_managers = admin_approval_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  admins = admin_approval_template.swimlanes.find_or_create_by!(name: 'Admins')

  # todo @martha - refactor for clarity
  start_workflow_event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
    name: 'start referral',
    template_id: admin_approval_template.id,
  )
  start_workflow_event.trigger_config = [
    {
      event: 'start_workflow',
      message: 'start_referral',
    },
  ]
  start_workflow_event.save!

  accept_workflow_event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
    name: 'accept referral',
    template_id: admin_approval_template.id,
  )
  accept_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'accept_referral',
    },
  ]
  accept_workflow_event.save!

  reject_workflow_event = Hmis::WorkflowDefinition::EndEvent.find_or_initialize_by(
    name: 'reject referral',
    template_id: admin_approval_template.id,
  )
  reject_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'reject_referral',
    },
  ]
  reject_workflow_event.save!

  client_acceptance_task = Hmis::WorkflowDefinition::Task.find_or_initialize_by(
    form_definition_id: client_accepts_form_def.id,
    template_id: admin_approval_template.id,
  )
  client_acceptance_task.name = 'Confirm Client Accepts Referral'
  client_acceptance_task.swimlane = case_managers

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

  admin_acceptance_task = Hmis::WorkflowDefinition::Task.find_or_initialize_by(
    form_definition_id: review_denial_form_def.id,
    template_id: admin_approval_template.id,
  )
  admin_acceptance_task.name = 'Review Denial'
  admin_acceptance_task.swimlane = admins

  client_acceptance_gateway = Hmis::WorkflowDefinition::Gateway.find_or_initialize_by(
    template: admin_approval_template,
    gateway_type: 'exclusive',
    name: 'client acceptance'
  )

  admin_review_gateway = Hmis::WorkflowDefinition::Gateway.find_or_initialize_by(
    template: admin_approval_template,
    gateway_type: 'exclusive',
    name: 'admin review'
  )
  start_workflow_event.connect_to!(client_acceptance_task) unless start_workflow_event.outflows.where(target_node_id: client_acceptance_task.id).exists?
  client_acceptance_task.connect_to!(client_acceptance_gateway) unless client_acceptance_task.outflows.where(target_node_id: client_acceptance_gateway.id).exists?
  client_acceptance_gateway.connect_to!(accept_workflow_event, condition: 'client_accepted = 1') unless client_acceptance_gateway.outflows.where(target_node_id: accept_workflow_event.id).exists?
  client_acceptance_gateway.connect_to!(admin_acceptance_task, condition: 'client_accepted = 0') unless client_acceptance_gateway.outflows.where(target_node_id: admin_acceptance_task.id).exists?
  admin_acceptance_task.connect_to!(admin_review_gateway) unless admin_acceptance_task.outflows.where(target_node_id: admin_review_gateway.id).exists?
  admin_review_gateway.connect_to!(client_acceptance_task, condition: 'review_denial_decision = 0') unless admin_review_gateway.outflows.where(target_node_id: client_acceptance_task.id).exists?
  admin_review_gateway.connect_to!(reject_workflow_event, condition: 'review_denial_decision = 1') unless admin_review_gateway.outflows.where(target_node_id: reject_workflow_event.id).exists?

  # TODO - hide conditional tasks
  # TODO - fix bug with sending back to a previous step; currently this causes a duplicate key error.

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
