desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  ::HmisUtil::JsonForms.new.tap do |builder|
    # Load ALL the latest record definitions from JSON files.
    # This also ensures that any system-level instances exist.
    builder.seed_record_form_definitions
    # Load ALL the latest assessment definition froms JSON files.
    builder.seed_assessment_form_definitions
    # In development, create the initial instances for occurrence-point collection.
    builder.create_default_occurrence_point_instances! if Rails.env.development?
  end
end

desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
  next unless data_source_id.present?

  # Create 1 CustomServiceCategory per HUD RecordType, and
  # 1 CustomServiceType per HUD TypeProvided
  ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
  # Create FormInstances specifying which Services are available per Project Type / Funder
  # NOTE: This should be run once on setup, but we don't want to re-run on each deploy
  # because each installation may need a different setup.
  ::HmisUtil::ServiceTypes.seed_hud_service_form_instances
end

desc 'Kick off job to create CustomAssessments by grouping related records'
task migrate_assessments: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id).each do |id|
    Hmis::MigrateAssessmentsJob.perform_later(data_source_id: id)
  end
end

# Seed user, org, and project to use with HMIS E2E Cypress tests
desc 'Seed E2E HMIS test data'
task seed_e2e: [:environment, 'log:info_to_stdout'] do
  next if Rails.env =~ /production|staging/

  system_user = Hmis::Hud::User.system_user(data_source_id: hmis_ds.id)

  # Find or create HMIS DS
  hmis_ds = GrdaWarehouse::DataSource.source.where(hmis: ENV['HMIS_HOSTNAME']).first_or_create! do |ds|
    ds.name = 'HMIS'
    ds.short_name = 'HMIS'
    ds.authoritative = true
  end

  # Find or create Test Organization
  test_org = Hmis::Hud::Organization.where(data_source: hmis_ds, organization_name: 'E2E Test Organization').
    first_or_create!(victim_service_provider: 0, user: system_user)
  test_org.projects.destroy_all # destroy all projects in org
  # Create Test Project
  Hmis::Hud::Project.create!(
    data_source_id: hmis_ds.id,
    organization_id: test_org.organization_id,
    project_name: 'E2E Test Project',
    user: system_user,
    operating_start_date: 1.year.ago,
    project_type: 1, # ES NBN
    continuum_project: 0,
  )

  # Find or create Test User
  e2e_email = 'e2e@example.com' # Do not change! frontend e2e tests rely on it
  e2e_pw = 'e2e-test-user' # Do not change! frontend e2e tests rely on it
  user = User.where(email: e2e_email).first_or_initialize(
    first_name: 'E2E Test',
    last_name: 'User',
    password: e2e_pw,
    confirmed_at: Time.current,
  )
  user.agency_id = Agency.where(name: 'Sample Agency').first_or_create!.id
  user.save!

  # Find or create Role
  role = Hmis::Role.where(name: 'E2E Test Role').first_or_initialize
  # Grant all permissions
  Hmis::Role.permissions_with_descriptions.keys.each do |perm|
    role.assign_attributes(perm => true)
  end
  role.save!

  # Find or create Access Group (Collection) with access to test org
  access_group = Hmis::AccessGroup.where(name: 'E2E Test Collection').first_or_create!
  access_group.add_viewable(test_org)
  # Find or create User Group
  user_group = Hmis::UserGroup.where(name: 'E2E Test Users').first_or_create!
  user_group.add(user)
  # Find or create ACL
  Hmis::AccessControl.where(role: role, access_group: access_group, user_group: user_group).first_or_create!
end
