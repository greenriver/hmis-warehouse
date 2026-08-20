###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'faker'

# To use SeedMaker outside of `db:seed` call `require './db/seed_maker'`
class SeedMaker
  def setup_fake_user
    return if User.find_by(email: 'noreply@example.com').present?

    User.transaction do
      # Add a user.  This should not be added in production
      return if Rails.env =~ /production|staging/

      production_seed_first_user(email: 'noreply@example.com', first_name: 'Sample', last_name: 'Admin')
    end
  end

  # For new deployments, call `production_seed_first_user` to create an initial user and associated access
  def production_seed_first_user(email:, first_name:, last_name:)
    raise "User #{email} already exists" if User.exists?(email: email)

    seed_roles

    developer = Role.find_by(name: 'Open Path Developer')
    agency = Agency.where(name: 'Green River').first_or_create

    # Setup an initial user
    initial_password = Faker::Internet.password(min_length: 16)
    user = User.new
    user.email = email
    user.first_name = first_name
    user.last_name = last_name
    user.password = user.password_confirmation = initial_password
    user.confirmed_at = Time.now
    user.permission_context = 'acls'
    user.agency_id = agency.id
    user.save!

    # legacy access
    developer.add(user)

    # Access Control access
    user_group = UserGroup.where(name: 'Open Path Developers').first_or_create
    user_group.add(user)
    all_ds_entity_collection = Collection.system_collection(:data_sources)
    AccessControl.create(role: developer, collection: all_ds_entity_collection, user_group: user_group)

    puts "Created initial admin email: #{user.email}  password: #{user.password}"
    user
  end

  # Not automatically called on deployment, but will be called for new installations
  # as part of the `production_seed_first_user` setup process
  # To reset roles to the default values, call `seed_roles(reset_permissions: true)`
  def seed_roles(reset_permissions: false)
    # Don't add any roles if you already have more than 3 roles (we can manually override with reset_permissions)
    return if Role.count > 3 && !reset_permissions

    YAML.load_file(Rails.root.join('db/seeds/roles.yaml')).each do |default_role|
      role = Role.where(name: default_role['name']).first_or_initialize
      # If the role already exists, skip it, we may have adjusted the permissions in the UI
      next if role.persisted? && !reset_permissions

      # ensure all permissions are false if we are resetting
      if reset_permissions
        Role.permissions_with_descriptions.each_key do |permission|
          role[permission] = false
        end
      end

      # set the permissions that are in this default role to true
      default_role['permissions'].each do |permission|
        raise unless Role.column_names.include?(permission)

        role[permission] = true
      end

      role.save!
    end
  end

  def maintain_cp_seed
    GrdaWarehouse::DataSource.where(short_name: 'Health').first_or_create do |ds|
      ds.name = 'Health'
      ds.authoritative = true
      ds.visible_in_window = false
      ds.authoritative_type = 'health'
      ds.save
    end

    Health::Cp.sender.first_or_create do |sender|
      sender.update(
        mmis_enrollment_name: 'COORDINATED CARE HUB',
        trace_id: 'OPENPATH00',
      )
    end
  end

  def maintain_data_sources
    GrdaWarehouse::DataSource.where(short_name: 'Warehouse').first_or_create do |ds|
      ds.name = 'HMIS Warehouse'
      ds.save
    end
  end

  def maintain_db_monitor_defaults
    AppConfigProperty.where(key: 'wh_db_space_monitor/alert_threshold_pct').first_or_create!(value: 10)
  end

  def maintain_lookups
    GrdaWarehouse::Lookups::CocCode.maintain!
    GrdaWarehouse::Lookups::YesNoEtc.transaction do
      GrdaWarehouse::Lookups::YesNoEtc.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::YesNoEtc.import(columns, HudHelper.util.no_yes_reasons_for_missing_data_options.to_a)
    end
    GrdaWarehouse::Lookups::LivingSituation.transaction do
      GrdaWarehouse::Lookups::LivingSituation.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::LivingSituation.import(columns, HudHelper.util.living_situations.to_a)
    end
    GrdaWarehouse::Lookups::ProjectType.transaction do
      GrdaWarehouse::Lookups::ProjectType.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::ProjectType.import(columns, HudHelper.util.project_types.to_a)
    end
    GrdaWarehouse::Lookups::FundingSource.transaction do
      GrdaWarehouse::Lookups::FundingSource.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::FundingSource.import(columns, HudHelper.util.funding_sources.to_a)
    end
    GrdaWarehouse::Lookups::Gender.transaction do
      GrdaWarehouse::Lookups::Gender.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::Gender.import(columns, HudHelper.util.genders.to_a)
    end
    GrdaWarehouse::Lookups::Relationship.transaction do
      GrdaWarehouse::Lookups::Relationship.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::Relationship.import(columns, HudHelper.util.relationships_to_hoh.to_a)
    end
  end

  def install_shapes
    return unless GrdaWarehouse::Shape::Installer.any_needed?

    begin
      Rake::Task['grda_warehouse:get_shapes'].invoke
    rescue Exception => e
      Rails.logger.tagged('shapes') do
        Rails.logger.fatal "Could not run shape importer: #{e.message}"
      end
    end
  end

  # These tables are partitioned with inheritance and need to have triggers and
  # functions that schema loading doesn't include.  This will ensure that they
  # exist on each deploy
  def ensure_db_triggers_and_functions
    Reporting::MonthlyReports::Base.ensure_triggers
  end

  def maintain_system_groups
    AccessGroup.maintain_system_groups
    Collection.maintain_system_groups(group: :data_sources)
  end

  # For local development only: set up initial HMIS data source and administrator access
  def setup_hmis_admin_access
    return unless ENV['HMIS_HOSTNAME'].present?
    return unless Rails.env.development?

    # Create HMIS Administrator role
    hmis_admin_role = Hmis::Role.where(can_administer_hmis: true).first_or_create! do |role|
      role.name = 'HMIS Administrator'
      role.can_view_project = true
      role.can_view_clients = true
    end

    # Create HMIS Data Source
    hostnames = ENV['HMIS_HOSTNAME'].split(',')
    raise 'hmis seed doesn\'t support multiple hostnames' if hostnames.size > 1

    hmis_ds = GrdaWarehouse::DataSource.source.where(hmis: hostnames.first).first_or_create! do |ds|
      ds.name = 'HMIS'
      ds.short_name = 'HMIS'
      ds.authoritative = true
    end

    return if hmis_admin_role.users.any?

    # Give a user HMIS Admin access by setting up a basic Access Control List
    user = Hmis::User.not_system.first
    return unless user.present?

    # Create Access Group (Collection) with data source access
    access_group = Hmis::AccessGroup.where(name: 'All HMIS Projects').first_or_create!
    access_group.add_viewable(hmis_ds)
    # Create User Group
    user_group = Hmis::UserGroup.where(name: 'Admin Users').first_or_create!
    user_group.add(user)
    # Create Access Control
    Hmis::AccessControl.where(
      role: hmis_admin_role,
      access_group: access_group,
      user_group: user_group,
    ).first_or_create!
    puts "#{user.name} is now an HMIS Administrator. Go to https://hmis-warehouse.dev.test/hmis_admin/roles to manage data access and permissions."
  end

  def load_hmis_data
    return unless ENV['ENABLE_HMIS_API'] == 'true'
    return unless GrdaWarehouse::DataSource.hmis.exists? # data source must be added in the warehouse UI

    # For each HMIS data source, seed JSON form definitions, HUD form instances, and HUD service type and category records
    GrdaWarehouse::DataSource.hmis.pluck(:id).each do |data_source_id|
      ::HmisUtil::JsonForms.seed_all(data_source_id: data_source_id)
      ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
    end
  end

  def populate_internal_system_choices
    return unless ENV['ENABLE_HMIS_API'] == 'true'

    HmisExternalApis::InternalSystem::NAMES.each do |name|
      sys = HmisExternalApis::InternalSystem.where(name: name).first_or_initialize
      if sys.new_record?
        Rails.logger.info "Creating #{name} internal system choice for Admin UI"
        sys.save!
      end
    end
  end

  def run_all
    ensure_db_triggers_and_functions
    Idp::ServiceConfig.bootstrap_from_env
    setup_fake_user if Rails.env.development?
    maintain_data_sources
    maintain_db_monitor_defaults
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    maintain_cp_seed
    setup_hmis_admin_access
    load_hmis_data
    install_shapes
    maintain_lookups
    GrdaWarehouse::Help.setup_default_links
    maintain_system_groups
    populate_internal_system_choices
    GrdaWarehouse::SystemColor.ensure_colors
    Translation.maintain_keys
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
  end
end
