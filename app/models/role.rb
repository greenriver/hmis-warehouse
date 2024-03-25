###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Role < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  include UserPermissionCache

  # Keep for health roles
  has_many :user_roles
  has_many :health_users, through: :user_roles
  # TODO: START_ACL remove after ACL migration is complete
  # has_many :user_roles, dependent: :destroy, inverse_of: :role
  has_many :legacy_users, through: :user_roles # FIXME: need to track down where we use this and update as appropriate
  # END_ACL

  has_many :access_controls, inverse_of: :role
  has_many :users, through: :access_controls

  after_save :invalidate_user_permission_cache
  validates :name, presence: true

  def role_name
    name.to_s
  end

  replace_scope :system, -> do
    not_system.where(system: true)
  end

  scope :not_system, -> do
    where(system: false)
  end

  scope :health, -> do
    where(health_role: true)
  end

  scope :editable, -> do
    not_system.where(health_role: false)
  end

  scope :homeless, -> do
    editable
  end

  scope :nurse_care_manager, -> do
    health.where(name: 'Nurse Care Manager')
  end

  scope :with_all_permissions, ->(*perms) do
    where(**perms.map { |p| [p, true] }.to_h)
  end

  scope :with_any_permissions, ->(*perms) do
    r_t = Role.arel_table
    where_clause = perms.map { |perm| r_t[perm.to_sym].eq(true) }.reduce(:or)
    where(where_clause)
  end

  scope :with_editable_permissions, -> do
    with_any_permissions(*permissions_for_access(:editable))
  end

  scope :with_viewable_permissions, -> do
    with_any_permissions(*permissions_for_access(:viewable))
  end

  def self.system_user_role
    where(
      system: true,
      name: 'System User Role',
      can_view_projects: true,
      can_edit_projects: true,
      can_manage_cohort_data: true,
      can_edit_project_groups: true,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
    ).first_or_create
  end

  def health?
    health_role
  end

  def has_super_admin_permissions? # rubocop:disable Naming/PredicateName
    Role.permissions.each do |permission,|
      return true if Role.super_admin_permissions.include?(permission) && self[permission]
    end
    false
  end

  def self.super_admin_permissions
    [
      :can_edit_roles,
      :can_edit_users,
      :can_manage_config,
      :can_manage_sessions,
      :can_edit_collections,
    ]
  end

  def administrative?
    Role.permissions_with_descriptions.each do |permission, description|
      return true if description[:administrative] && self[permission]
    end
    false
  end

  def self.permissions(exclude_health: false)
    perms = permissions_with_descriptions.keys
    perms += self.health_permissions unless exclude_health # rubocop:disable Style/RedundantSelf
    return perms
  end

  def self.permission_categories
    permissions_with_descriptions.map { |_perm_key, perm| perm[:category] }
  end

  def self.health_permissions
    health_permissions_with_descriptions.keys
  end

  def self.description_for permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:description] rescue '' # rubocop:disable Style/RescueModifier
  end

  def self.category_for permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:category] rescue [] # rubocop:disable Style/RescueModifier
  end

  def self.administrative? permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:administrative] rescue true # rubocop:disable Style/RescueModifier
  end

  def self.permissions_for_access(access)
    permissions_with_descriptions.select { |_k, attrs| attrs[:access].include?(access) }.keys
  end

  def self.permissions_by_group
    {}.tap do |perms|
      permissions_with_descriptions.each do |key, role|
        perms[role[:category]] ||= {}
        perms[role[:category]][role[:sub_category]] ||= {}
        perms[role[:category]][role[:sub_category]][key] = role
      end
    end
  end

  def enabled_permissions
    self.class.permissions_with_descriptions.select { |k, _| send(k) }
  end

  # Pick a background color that is unique to the name, but not terribly vibrant
  def bg_color
    @bg_color ||= begin
      random_color = Digest::MD5.hexdigest(name)[0, 6]
      hsl = GrdaWarehouse::SystemColor.new.hsl(random_color)
      hsl[:l] += 20 if hsl[:l] < 70
      hsl[:s] -= 30 if hsl[:s] > 40
      "##{GrdaWarehouse::SystemColor.new.hsl_to_hex(hsl)}"
    end
  end

  def fg_color
    @fg_color ||= GrdaWarehouse::SystemColor.new.calculated_foreground_color(bg_color)
  end

  def self.permissions_with_descriptions
    {
      can_view_clients: {
        description: 'Allows access to view client details based on client data source and enrollments via user\'s access.',
        administrative: false,
        category: 'Client Access',
        sub_category: 'General Client Access',
      },
      can_view_client_enrollments_with_roi: {
        description: 'When combined with an Entity Group through an Access Control, exposes enrollments at projects in the entity group for clients with an active ROI in a CoC assigned to the user.',
        administrative: false,
        category: 'Client Access',
        sub_category: 'General Client Access',
      },
      can_edit_clients: {
        description: 'Provides the ability to merge clients and make other edits. This should only be given to administrator level users.',
        administrative: true,
        category: 'Client Access',
        sub_category: 'Administrative',
      },
      can_view_chronic_tab: {
        description: 'Provides the ability to view the chronic tab for a client.',
        administrative: false,
        category: 'Client Access',
        sub_category: 'General Client Access',
      },
      can_view_full_client_dashboard: {
        description: 'Given access to a client\'s enrollments, user is able to see all sections of a client dashboard',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Dashboard',
        single_choice_category: 'client_dashboard',
      },
      can_view_limited_client_dashboard: {
        description: 'Given access to a client\'s enrollments, user is able to see some sections of a client dashboard',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Dashboard',
        single_choice_category: 'client_dashboard',
      },
      can_audit_clients: {
        description: 'Access to see who has looked at or changed a client record. This should only be given to administrator level users.',
        administrative: true,
        category: 'Client Access',
        sub_category: 'Administrative',
      },
      can_edit_users: {
        description: 'Ability to add and edit user accounts for all users',
        administrative: true,
        category: 'Administration',
        sub_category: 'User Rights',
      },
      can_enable_2fa: {
        description: 'Ability to enable Two-factor authentication for own account',
        administrative: false,
        category: 'Administration',
        sub_category: 'Account Security',
      },
      enforced_2fa: {
        description: 'Users with this permission will be unable to login until Two-factor authentication has been enabled',
        administrative: false,
        category: 'Administration',
        sub_category: 'Account Security',
      },
      training_required: {
        description: 'Users with this permission will be unable to login until they have completed user training.',
        administrative: false,
        category: 'Administration',
        sub_category: 'Account Security',
      },
      can_edit_roles: {
        description: 'Ability to add and remove roles and assign permissions to all roles',
        administrative: true,
        category: 'Administration',
        sub_category: 'User Rights',
      },
      can_edit_collections: {
        description: 'Ability to add and remove groups and assign entities to all groups',
        administrative: true,
        category: 'Administration',
        sub_category: 'User Rights',
      },
      can_audit_users: {
        description: 'Access to the audit logs for users',
        administrative: true,
        category: 'Administration',
        sub_category: 'Auditing',
      },
      can_view_full_ssn: {
        description: 'Ability to see the full Social Security Number for clients',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_full_dob: {
        description: 'Ability to see the Date of Birth for clients',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_hiv_status: {
        description: 'Ability to see the HIV information for clients',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_dmh_status: {
        description: 'Ability to see the Mental Health information for clients',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_imports: {
        description: 'Access to the HUD HMIS import section, must be used in conjunction with access to a data source and assignment of at least one data source.',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_view_projects: {
        description: 'Read-only access to projects.  This also grants access to the list of clients who are or have been enrolled at the projects.  Can be used in conjunction with assignments to data sources, organizations, or projects.',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_edit_projects: {
        description: 'Edit level access for projects and project overrides',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_import_project_groups: {
        description: 'Import groupings of projects, this process is un-aware of user project-group associations',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_edit_project_groups: {
        description: 'Setup groupings of projects, mostly for reporting',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_edit_assigned_project_groups: {
        description: 'Setup groupings of projects, limited to those assigned to the user',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_view_organizations: {
        description: 'Read-only access to organization attributes',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_edit_organizations: {
        description: 'Edit level access for organizations and organization overrides',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      can_edit_data_sources: {
        description: 'Add or Edit data sources, including specifying if it is visible in the window',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Project Access',
      },
      # TODO: START_ACL remove after ACL migration is complete
      # DEPRECATED, superseded by can_search_own_clients in combination with access controls
      can_search_all_clients: {
        description: 'Given access to a client search, via can search window or can use strict search, allow the user to see the search results for all clients, regardless of if they can see other demographic data',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Search',
      },
      # DEPRECATED, superseded by can_search_own_clients in combination with access controls
      can_search_window: {
        description: 'Limited access to the data available in the window.  This should be given to any role that has access to client window data. Assigning "Can View Clients" will take precedence and grant additional access',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Search',
      },
      # END_ACL
      can_use_strict_search: {
        description: 'Access to the client search screen that requires more exact matching. To search at all, user must also have "Can search own clients".',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Search',
      },
      can_search_own_clients: {
        description: 'Ability to use some version of the client search. If no additional search permissions are chosen, the user can use the free-form search. You can enforce the strict search by also selecting the Can use strict search permission. Must be used in conjunction with "Can View Clients" for access to client dashboards (NOTE: used in ACLs)',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Search',
      },
      can_search_clients_with_roi: {
        description: 'When combined with an Entity Group through an Access Control, exposes clients with an active ROI in a CoC assigned to the user in search results (NOTE: used in ACLs)',
        administrative: false,
        category: 'Client Access',
        sub_category: 'Client Search',
      },
      can_view_cached_client_enrollments: {
        description: 'Ability to see all enrollments for a client as cached in the history log of client enrollments.  There is no limit imposed on these cached views.',
        administrative: true,
        category: 'Client Access',
        sub_category: 'Client Dashboard',
      },
      can_upload_hud_zips: {
        description: 'Access to upload HMIS files from external systems',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_edit_translations: {
        description: 'Ability to translate strings from the default OpenPath language to community specific langauge',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
      can_manage_assessments: {
        description: 'Allows access to the administrative view of ETO TouchPoints',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
      can_manage_client_files: {
        description: 'Ability to view, upload, and delete client files, and control which files are visible in the window',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_manage_window_client_files: {
        description: 'Ability to view, upload, and delete files in the window for clients with active confirmed consent or files uploaded by this user',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_generate_homeless_verification_pdfs: {
        description: 'Allows access to generate and view homeless verification PDFs for any client for which the user has access',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_see_own_file_uploads: {
        description: 'Access to files this user has uploaded, no access to others.  Usually used for community members who might be collecting files, but shouldn\'t see files provided by others',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_see_confidential_files: {
        description: 'Access to client confidential files.  Without this, a user can see that the file exists, which labels were applied to it, and when it was uploaded, but not what is in the file. Access is limited to the associated projects, files must be assigned to a project.',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'Privacy',
      },
      can_use_separated_consent: {
        description: 'If granted, the user will see a top level consent option for clients.  If unchecked, consent will fall under the files tab',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_manage_config: {
        description: 'Administrative ability to fundamentally change the way various items are calculated and to disable/enable modules',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
      can_manage_sessions: {
        description: 'If granted, the user can see a list of active sessions and can cancel any session',
        administrative: true,
        category: 'Administration',
        sub_category: 'Auditing',
      },
      can_view_vspdat: {
        description: 'Access to view existing VI-SPDAT records',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_vspdat: {
        description: 'Ability to edit existing VI-SPDAT records',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_submit_vspdat: {
        description: 'Ability to add VI-SPDAT records',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_view_ce_assessment: {
        description: 'Access to view existing Coordinated Entry Assessments',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_ce_assessment: {
        description: 'Ability to edit existing Coordinated Entry Assessments',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_submit_ce_assessment: {
        description: 'Ability to add Coordinated Entry Assessments',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_view_youth_intake: {
        description: 'Access to existing Youth Intake records',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_youth_intake: {
        description: 'Ability to add or edit Youth Intake records',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_delete_youth_intake: {
        description: 'The ability to delete a Youth Intake record',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_view_own_agency_youth_intake: {
        description: 'Access to existing Youth Intake records associated with the User\'s agency',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_own_agency_youth_intake: {
        description: 'Ability to add or edit Youth Intake records associated with the User\'s agency,',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_create_clients: {
        description: 'Given an authoritative data source, users can add clients that don\'t exist in HMIS',
        administrative: false,
        category: 'Client Access',
        sub_category: 'General Client Access',
      },
      can_view_client_history_calendar: {
        description: 'Access to the calendar view of client enrollments',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_view_client_locations: {
        description: 'Access to the map view of client locations',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'Privacy',
      },
      can_view_enrollment_details: {
        description: 'Grants access to the enrollment details tab. Includes all related records such as Assessments, Services, Current Living Situations, and more.',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_client_notes: {
        description: 'Ability to edit any client note, used to remove inappropriate notes',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_own_client_notes: {
        description: 'Ability to edit client notes that the user created',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_edit_window_client_notes: {
        description: 'Ability to edit any client note in the window, used to remove inappropriate notes',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_see_own_window_client_notes: {
        description: 'Access to notes created by the user in the window',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_view_all_window_notes: {
        description: 'User will be able to see notes for any client they can already see, this includes only notes of type Window Note, Alert, or Emergency Contact',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'General Client Access',
      },
      can_configure_cohorts: {
        description: 'Ability to create, configure, and remove cohorts',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Administration',
      },
      can_add_cohort_clients: {
        description: 'Ability to add, remove, and import cohort clients',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_manage_cohort_data: {
        description: "Ability to modify all visible cohort client data (except for 'Active')",
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_view_cohorts: {
        description: 'Ability to view, but not modify, cohorts',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_participate_in_cohorts: {
        description: 'Ability to modify editable visible cohort client data',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_view_inactive_cohort_clients: {
        description: 'Ability to view inactive cohort clients',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_manage_inactive_cohort_clients: {
        description: 'Ability to update if client cohorts are active (grants the ability to see inactive clients)',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_download_cohorts: {
        description: 'Ability to download the contents of a cohort',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_view_deleted_cohort_clients: {
        description: 'Ability to view the clients removed from a cohort',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_view_cohort_client_changes_report: {
        description: 'Ability to view the history of clients added and removed from a cohort',
        administrative: false,
        category: 'Cohorts',
        sub_category: 'Cohort Usage',
      },
      can_assign_users_to_clients: {
        description: 'Ability to setup user-client relationships',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'Relationships',
      },
      can_view_client_user_assignments: {
        description: 'Read-only access to see user-client relationships',
        administrative: false,
        category: 'Client Extras',
        sub_category: 'Relationships',
      },
      can_export_hmis_data: {
        description: 'When combined with assignment of the appropriate report, allows a user to export HMIS data',
        administrative: false,
        category: 'Reporting',
        sub_category: 'Exporting',
      },
      can_export_anonymous_hmis_data: {
        description: 'Fake data exports for developers',
        administrative: true,
        category: 'Reporting',
        sub_category: 'Exporting',
      },
      can_confirm_housing_release: {
        description: 'Ability to confirm uploaded housing releases',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'Consent Management',
      },
      can_track_anomalies: {
        description: 'Access to identify data anomalies for clients and report them',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'Auditing',
      },
      can_view_all_reports: {
        description: 'Access to all reports, regardless the user who ran the report',
        administrative: true,
        category: 'Reporting',
        sub_category: 'Report Access',
      },
      can_assign_reports: {
        description: 'Ability to specify which reports other users can see, the other users must have the "Can view assigned reports" permission and reports assigned on the user edit screen',
        administrative: true,
        category: 'Reporting',
        sub_category: 'Report Administration',
      },
      can_view_assigned_reports: {
        description: 'Required for access to reports assigned to a user and to indicate which projects a user can report on',
        administrative: false,
        category: 'Reporting',
        sub_category: 'Report Access',
      },
      can_administer_assigned_reports: {
        description: 'Ability to view and delete reports assigned to other users',
        administrative: true,
        category: 'Reporting',
        sub_category: 'Report Administration',
      },
      can_view_project_related_filters: {
        description: 'Ability to specify filters of project, organization, funding source and data sources.  Most single CoC installations will want this enabled for anyone with reporting access.',
        administrative: false,
        category: 'Reporting',
        sub_category: 'Data Access',
      },
      can_publish_reports: {
        description: 'Ability to publish reports to a public facing website (S3)',
        administrative: false,
        category: 'Reporting',
        sub_category: 'Exporting',
      },
      can_view_all_user_client_assignments: {
        description: 'Administrative permission to see all assignments',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'Relationships',
      },
      can_add_administrative_event: {
        description: 'Ability to create administrative events for tracking changes over time',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Administration',
      },
      can_upload_deidentified_hud_hmis_files: {
        description: 'When combined with the ability to upload HUD HMIS files, shows an option to replace PII on ingestion',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_upload_whitelisted_hud_hmis_files: {
        description: 'When combined with the ability to upload HUD HMIS files, imports only clients who have touched an allowed project',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_edit_warehouse_alerts: {
        description: 'Ability to create and edit warehouse-wide alerts',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Administration',
      },
      can_edit_theme: {
        description: 'Access to the site theme',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Administration',
      },
      can_upload_dashboard_extras: {
        description: 'Access to upload the supplemental enrollment data for a data source',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_view_all_secure_uploads: {
        description: 'Access to see all "secure" uploaded files',
        administrative: true,
        category: 'Administration',
        sub_category: 'Data Sharing',
      },
      can_view_assigned_secure_uploads: {
        description: 'Access to see assigned "secure" uploaded files',
        administrative: false,
        category: 'Administration',
        sub_category: 'Data Sharing',
      },
      can_manage_agency: {
        description: 'Ability to manage users associated with my agency',
        administrative: true,
        category: 'Administration',
        sub_category: 'Agency Administration',
      },
      can_manage_all_agencies: {
        description: 'Ability to manage all agencies',
        administrative: true,
        category: 'Administration',
        sub_category: 'Agency Administration',
      },
      can_edit_help: {
        description: 'Ability to maintain help documents',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
      can_view_all_hud_reports: {
        description: 'This permission grants access to run all HUD reports, limited by data access assignments.  In addition, this grants access to all HUD reports that have ever been run regardless of access assignments.',
        administrative: true,
        category: 'Reporting',
        sub_category: 'HUD Reports',
      },
      can_view_own_hud_reports: {
        description: 'This permission grants access to run all HUD reports, limited by data access assignments.  Users can only see results for HUD reports they initiated.',
        administrative: false,
        category: 'Reporting',
        sub_category: 'HUD Reports',
      },
      can_view_confidential_project_names: {
        description: 'Anyone with this permission will see the name of confidential projects when displayed within reports or on client dashboards. To include confidential projects in reports, users must also be able to Report on Confidential Projects. NOTE: for Access Controls, this is limited to associated projects',
        administrative: true,
        category: 'Client Extras',
        sub_category: 'Confidentiality',
      },
      can_report_on_confidential_projects: {
        description: 'Reports for users with this permission will include confidential projects.  The names of confidential projects will not be exposed unless the user an also view confidential project names.  Users without this permission will exclude any confidential projects.',
        administrative: true,
        category: 'Reporting',
        sub_category: 'Confidentiality',
      },
      can_manage_ad_hoc_data_sources: {
        description: 'Can this user manage Ad-Hoc Data sources?',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_manage_own_ad_hoc_data_sources: {
        description: 'Grants the ability to create and manage Ad-Hoc Data sources they create.',
        administrative: false,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_view_client_ad_hoc_data_sources: {
        description: 'Can this user see if a client matched Ad-Hoc Data sources?',
        administrative: false,
        category: 'Client Access',
        sub_category: 'General Client Access',
      },
      can_impersonate_users: {
        description: 'Can become any other user.  Anyone with this permission can impersonate any other user and see whatever they would see.',
        administrative: true,
        category: 'Administration',
        sub_category: 'Debugging',
      },
      can_delete_projects: {
        description: 'Deleting projects will delete all associated inventory and enrollment information.',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_delete_data_sources: {
        description: 'Can delete data sources, organizations or projects. Deleting any of these will delete all associated inventory and enrollment information.',
        administrative: true,
        category: 'Data Sources & Inventory',
        sub_category: 'Importing',
      },
      can_see_health_emergency: {
        description: 'Ability to see any health emergency information when health emergencies are enabled.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_edit_health_emergency_medical_restriction: {
        description: 'Ability to edit medical restrictions during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_edit_health_emergency_screening: {
        description: 'Ability to edit and delete screening records during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_edit_health_emergency_clinical: {
        description: 'Ability to edit and delete clinical records during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_see_health_emergency_history: {
        description: 'Ability to see client emergency history during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_see_health_emergency_medical_restriction: {
        description: 'Ability to see medical restrictions during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_see_health_emergency_screening: {
        description: 'Ability to see and delete screening records during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_see_health_emergency_clinical: {
        description: 'Ability to see and delete clinical records during a health emergency.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      receives_medical_restriction_notifications: {
        description: 'Email notifications will be sent whenever a medical restriction or test result is added.',
        administrative: false,
        category: 'Health Emergency',
        sub_category: 'Access',
      },
      can_use_service_register: {
        description: 'Grants the ability to scan individual services for a given program.',
        administrative: false,
        category: 'Service Register',
        sub_category: 'Access',
      },
      can_view_service_register_on_client: {
        description: 'Grants the ability to view services from the service register for a given client.',
        administrative: false,
        category: 'Service Register',
        sub_category: 'Access',
      },
      can_manage_auto_client_de_duplication: {
        description: 'Ability to see statistics around client de-duplication and set the threshold for probabilistic matching.',
        administrative: true,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
      can_manage_inbound_api_configurations: {
        description: 'Can manage configuration (e.g. API keys) for external systems connecting to ours',
        administrative: false,
        category: 'Administration',
        sub_category: 'Site Configuration',
      },
    }
  end

  def self.health_permissions_with_descriptions
    {
      can_administer_health: {
        description: 'Administrative access to all health sections and patient records',
        administrative: true,
        categories: [],
      },
      can_edit_client_health: {
        description: 'Provides the ability to enter data for pilot patients. Pilot Permission',
        administrative: false,
        categories: [],
      },
      can_view_client_health: {
        description: 'Ability to view pilot patient records. Pilot Permission',
        administrative: false,
        categories: [],
      },
      can_view_aggregate_health: {
        description: 'Access to see the claims and ED use data provided from BHCHP',
        administrative: true,
        categories: [],
      },
      can_manage_health_agency: {
        description: 'Ability to add and edit health agency records',
        administrative: true,
        categories: [],
      },
      can_approve_patient_assignments: {
        description: 'Ability to convert patient referrals to patient records and assign patients to agencies',
        administrative: true,
        categories: [],
      },
      can_manage_claims: {
        description: 'Can generate, review, and download claims files',
        administrative: true,
        categories: [],
      },
      can_manage_all_patients: {
        description: 'Ability to claim patient referrals for any agency',
        administrative: true,
        categories: [],
      },
      can_manage_patients_for_own_agency: {
        description: 'Ability to claim patient referrals for an agency, used in conjunction with user-agency assignments',
        administrative: false,
        categories: [],
      },
      can_manage_care_coordinators: {
        description: 'Assign care coordinators to patients',
        administrative: false,
        categories: [],
      },
      can_approve_cha: {
        description: 'Ability to approve Comprehensive Health Assessments',
        administrative: false,
        categories: [],
      },
      can_approve_ssm: {
        description: 'Ability to approve Self-Sufficiency Matrix forms',
        administrative: false,
        categories: [],
      },
      can_approve_release: {
        description: 'Ability to approve release forms',
        administrative: false,
        categories: [],
      },
      can_approve_participation: {
        description: 'Ability to approve participation forms',
        administrative: false,
        categories: [],
      },
      can_approve_careplan: {
        description: 'Ability to approve Care Plans',
        administrative: false,
        categories: [],
      },
      can_edit_all_patient_items: {
        description: 'Unused',
        administrative: true,
        categories: [],
      },
      can_edit_patient_items_for_own_agency: {
        description: 'Edit ability for patient records',
        administrative: false,
        categories: [],
      },
      can_create_care_plans_for_own_agency: {
        description: 'Unused',
        administrative: false,
        categories: [],
      },
      can_view_all_patients: {
        description: 'Unused',
        administrative: true,
        categories: [],
      },
      can_view_patients_for_own_agency: {
        description: 'Allows access to patient records',
        administrative: false,
        categories: [],
      }, # Read-only - not implemented as such yet
      can_add_case_management_notes: {
        description: 'Unused',
        administrative: false,
        categories: [],
      },
      can_manage_accountable_care_organizations: {
        description: 'Administer ACO records',
        administrative: true,
        categories: [],
      },
      can_view_member_health_reports: {
        description: 'Use for downloading individual member reports',
        administrative: true,
        categories: [],
      },
      can_unsubmit_submitted_claims: {
        description: 'Can this user blank out the submitted date on QA, allowing resubmission?',
        administrative: true,
        categories: [],
      },
      can_edit_health_emergency_contact_tracing: {
        description: 'Grants access to the contact tracing section when there is an active health emergency',
        administrative: false,
        categories: [],
      },
      can_view_all_vprs: {
        description: 'Can view Flex Services information for all patients',
        administrative: true,
        categories: [],
      },
      can_view_my_vprs: {
        description: 'Can view Flex Services information for assigned patients',
        administrative: false,
        categories: [],
      },
    }
  end

  def self.ensure_permissions_exist
    Role.permissions.each do |permission|
      ActiveRecord::Migration.add_column(:roles, permission, :boolean, default: false) unless ActiveRecord::Base.connection.column_exists?(:roles, permission)
    end
  end

  # Only used in the Healthcare context (once ACL migration is complete) START_ACL
  def add(users)
    self.health_users = (health_users + Array.wrap(users)).uniq
    self.legacy_users = (legacy_users + Array.wrap(users)).uniq # START_ACL remove after ACL migration is complete
  end

  def remove(users)
    self.health_users = (health_users - Array.wrap(users))
    self.legacy_users = (legacy_users - Array.wrap(users)) # START_ACL remove after ACL migration is complete
  end
end
