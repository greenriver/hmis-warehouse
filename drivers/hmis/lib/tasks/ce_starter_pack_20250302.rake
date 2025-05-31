# Helpers to reduce cruft and make the starter pack script more readable
def create_template(name, identifier)
  template = Hmis::WorkflowDefinition::Template.find_or_initialize_by(
    identifier: identifier,
    status: 'published'
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
    form_definition_identifier: definition.identifier,
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
  start_workflow_event = create_start_event(no_task_template, 'start referral', 'start_workflow', 'start_referral')
  accept_workflow_event = create_end_event(no_task_template, 'accept referral', 'end_workflow', 'accept_referral')
  start_workflow_event.connect_to!(accept_workflow_event) unless start_workflow_event.outflows.where(target_node_id: accept_workflow_event.id).exists?

  puts '- Creating One Task template, another simple template that has 1 task, which can cause the referral to either succeed or fail.'
  one_task_template = create_template('One Task', 'one_task')
  case_managers = one_task_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  start_workflow_event = create_start_event(one_task_template, 'start referral', 'start_workflow', 'start_referral')
  accept_workflow_event = create_end_event(one_task_template, 'accept referral', 'end_workflow', 'accept_referral')
  reject_workflow_event = create_end_event(one_task_template, 'reject referral', 'end_workflow', 'reject_referral')

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

  start_workflow_event = create_start_event(admin_approval_template, 'start referral', 'start_workflow', 'start_referral')
  accept_workflow_event = create_end_event(admin_approval_template, 'accept referral', 'end_workflow', 'accept_referral')
  reject_workflow_event = create_end_event(admin_approval_template, 'reject referral', 'end_workflow', 'reject_referral')

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

  puts '- Creating Sequential template, a template with non-conditional tasks that are executed sequentially.'
  sequential_template = create_template('Sequential', 'sequential')
  case_managers = sequential_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  providers = sequential_template.swimlanes.find_or_create_by!(name: 'Providers')
  start_workflow_event = create_start_event(sequential_template, 'start referral', 'start_workflow', 'start_referral')
  accept_workflow_event = create_end_event(sequential_template, 'accept referral', 'end_workflow', 'accept_referral')

  task_1 = create_task(client_accepts_form_def, sequential_template,  'Case Manager Confirm', case_managers)
  task_2 = create_task(review_denial_form_def, sequential_template,  'Provider Confirm', providers)

  start_workflow_event.connect_to!(task_1) unless start_workflow_event.outflows.where(target_node_id: task_1.id).exists?
  task_1.connect_to!(task_2) unless task_1.outflows.where(target_node_id: task_2.id).exists?
  task_2.connect_to!(accept_workflow_event) unless task_2.outflows.where(target_node_id: accept_workflow_event.id).exists?

  puts '- Creating Enrollment Creator template, a template with tasks that have side effects.'

  enrollment_creator_template = create_template('Enrollment Creator', 'enrollment_creator')
  case_managers = enrollment_creator_template.swimlanes.find_or_create_by!(name: 'Case Managers')
  providers = enrollment_creator_template.swimlanes.find_or_create_by!(name: 'Providers')

  start_workflow_event = create_start_event(enrollment_creator_template, 'start referral', 'start_workflow', 'start_referral')
  accept_workflow_event = create_end_event(enrollment_creator_template, 'accept referral', 'end_workflow', 'accept_referral')

  client_acceptance_task = create_task(client_accepts_form_def, enrollment_creator_template,  'Confirm Client Accepts Referral', providers)
  create_enrollment_form_def = Hmis::Form::Definition.find_or_initialize_by(
    identifier: 'ce_create_enrollment',
    status: 'published'
  )
  create_enrollment_form_def.title = 'Create Enrollment'
  create_enrollment_form_def.role = 'CE_REFERRAL_STEP'
  create_enrollment_form_def.version ||= 0
  create_enrollment_form_def.definition = {
    "item": [
      {
        "text": "Move-in Date",
        "type": "DATE",
        "link_id": "move_in_date",
        "required": true,
        'mapping': { 'field_name': 'moveInDate', 'record_type': 'ENROLLMENT' },
      },
    ]
  }
  create_enrollment_form_def.save! if create_enrollment_form_def.changed?

  create_enrollment_task = create_task(create_enrollment_form_def, enrollment_creator_template,  'Create Enrollment', case_managers)
  create_enrollment_task.trigger_config = [
    { # 1. Create an enrollment
      event: 'complete_step',
      message: 'create_enrollment',
    },
    { # 2. Set move-in date
      event: 'complete_step',
      message: 'set_move_in_date',
    }
  ]
  create_enrollment_task.save! if create_enrollment_task.changed?

  start_workflow_event.connect_to!(create_enrollment_task) unless start_workflow_event.outflows.where(target_node_id: create_enrollment_task.id).exists?
  start_workflow_event.connect_to!(client_acceptance_task) unless start_workflow_event.outflows.where(target_node_id: client_acceptance_task.id).exists?
  create_enrollment_task.connect_to!(accept_workflow_event) unless create_enrollment_task.outflows.where(target_node_id: accept_workflow_event.id).exists?
  client_acceptance_task.connect_to!(accept_workflow_event) unless client_acceptance_task.outflows.where(target_node_id: accept_workflow_event.id).exists?

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

  project_coc = Hmis::Hud::ProjectCoc.find_or_initialize_by(
    data_source_id: hmis_ds.id,
    project_id: ce_project.project_id,
    coc_code: 'CO-500',
  )
  project_coc.geocode = '250396'
  project_coc.user ||= system_user
  project_coc.save! if project_coc.changed?

  ce_project_funder = ce_project.funders.find_or_initialize_by(data_source: ce_project.data_source)
  ce_project_funder.funder = 20
  ce_project_funder.user = system_user
  ce_project_funder.data_source = ce_project.data_source
  ce_project_funder.start_date ||= 3.years.ago
  ce_project_funder.grant_id = 'grant ID'
  ce_project_funder.save! if ce_project_funder.changed?

  # Set up match rules in this project
  puts 'Creating match rules'
  age_requirement = Hmis::Ce::Match::Rule.find_or_initialize_by(
    expression: 'current_age >= 18',
    rule_type: 'eligibility_requirement',
    owner: ce_project,
  )
  age_requirement.name = 'Must be 18+ years old'
  age_requirement.applicability_config = {}
  age_requirement.save! if age_requirement.changed?

  veteran_requirement = Hmis::Ce::Match::Rule.find_or_initialize_by(
    expression: 'veteran_status == 1',
    rule_type: 'eligibility_requirement',
    owner: ce_project,
  )
  veteran_requirement.name = 'Must be veteran'
  veteran_requirement.applicability_config = {
    'project_funders': [ce_project_funder.id]
  }
  veteran_requirement.save! if veteran_requirement.changed?

  days_homeless_priority = Hmis::Ce::Match::Rule.find_or_initialize_by(
    expression: 'days_homeless',
    rule_type: 'priority_scheme',
    owner: ce_project,
  )
  days_homeless_priority.name = 'Total Days Homeless'
  days_homeless_priority.applicability_config = {}
  days_homeless_priority.save! if days_homeless_priority.changed?

  # Create candidates for opportunities. First create some opportunities using the frontend
  puts 'Building a candidate pool'
  opportunities = Hmis::Ce::Opportunity.active
  Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform

  puts 'Running the CE match engine'
  clients = Hmis::Hud::Client.hmis.limit(100) # modify this if you want to include different or specific clients
  Hmis::Ce::Match::CandidatePool.all.each do |pool|
    Hmis::Ce::Match::Engine.call(pool, clients)
  end

  if Hmis::Ce::Opportunity.open.any?
    # Create some opportunities with Opportunity Categories, just to show how it looks in the UI
    sro = Hmis::Ce::OpportunityCategory.find_or_create_by(name: 'SRO')
    sro_opportunity = Hmis::Ce::Opportunity.open.first
    Hmis::Ce::OpportunityCategorization.find_or_create_by(
      opportunity: sro_opportunity,
      category: sro
    )

    accessible_sro = Hmis::Ce::OpportunityCategory.find_or_create_by(name: 'Accessible SRO')
    accessible_sro_opportunity = Hmis::Ce::Opportunity.open.last
    Hmis::Ce::OpportunityCategorization.find_or_create_by(
      opportunity: accessible_sro_opportunity,
      category: accessible_sro
    )
  end
end
