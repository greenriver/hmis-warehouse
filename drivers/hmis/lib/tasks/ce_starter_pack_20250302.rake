desc 'Script to populate local dev databases with "starter-pack" CE records like templates, swimlanes, and tasks'
# rails driver:hmis:ce_starter_pack_20250302
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
  no_task_template.name ||= 'No Tasks'
  no_task_template.version ||= 0
  no_task_template.save! if no_task_template.changed?
  case_managers = no_task_template.swimlanes.find_or_create_by!(name: 'Case Managers')

  start_workflow_event = Hmis::WorkflowDefinition::StartEvent.find_or_initialize_by(
    name: 'start referral',
    template_id: no_task_template.id,
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
    name: 'accept workflow',
    template_id: no_task_template.id,
  )
  accept_workflow_event.swimlane_id = case_managers.id
  accept_workflow_event.trigger_config = [
    {
      event: 'end_workflow',
      message: 'accept_referral',
    },
  ]
  accept_workflow_event.save!

  start_workflow_event.connect_to!(accept_workflow_event) unless start_workflow_event.outflows.where(target_node_id: accept_workflow_event.id).exists?

  # TODO(#7309) - here, add a more complicated workflow template that has several tasks, form definitions, more dependencies, multiple swimlanes etc.

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
  clients = Hmis::Hud::Client.all.limit(100) # modify this if you want to include different or specific clients
  Hmis::Ce::Match::CandidatePool.all.each do |pool|
    Hmis::Ce::Match::Engine.call(pool, clients)
  end
end
