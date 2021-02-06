###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy, inverse_of: :role
  has_many :users, through: :user_roles
  validates :name, presence: true

  def role_name
    name.to_s
  end

  scope :health, -> do
    where(health_role: true)
  end

  scope :editable, -> do
    where(health_role: false)
  end

  scope :nurse_care_manager, -> do
    health.where(name: 'Nurse Care Manager')
  end

  def has_super_admin_permissions?
    Role.permissions.each do |permission,|
      return true if Role.super_admin_permissions.include?(permission) && self[permission]
    end
    false
  end

  def self.super_admin_permissions
    [
      :can_edit_roles,
      :can_edit_users,
      :can_edit_anything_super_user, # deprecated
      :can_manage_config,
      :can_edit_access_groups,
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
    perms += self.health_permissions unless exclude_health
    return perms
  end

  def self.permission_categories
    permissions_with_descriptions.map{|perm_key, perm| perm[:categories]}.flatten.uniq
  end

  def self.health_permissions
    health_permissions_with_descriptions.keys
  end

  def self.description_for permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:description] rescue ''
  end

  def self.category_for permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:categories] rescue []
  end

  def self.administrative? permission:
    permissions_with_descriptions.merge(health_permissions_with_descriptions)[permission][:administrative] rescue true
  end


  def self.permissions_with_descriptions
    {
      can_edit_anything_super_user: {
        description: 'This permission grants access to all data sources, organizations and projects, regardless of assignment. This should only be given to administrator level users.',
        administrative: true,
        categories: [
          'Administration',
          'Client Access',
          'Data Sources & Inventory',
        ],
      },
      can_view_clients: {
        description: 'Allows access to the non-window view of clients. This should only be given to administrator level users.',
        administrative: true,
        categories: [
          'Client Access',
        ],
      },
      can_edit_clients: {
        description: 'Provides the ability to merge clients and make other edits. This should only be given to administrator level users.',
        administrative: true,
        categories: [
          'Client Access',
        ],
      },
      can_audit_clients: {
        description: 'Access to see who has looked at or changed a client record. This should only be given to administrator level users.',
        administrative: true,
        categories: [
          'Client Access',
        ],
      },
      can_view_census_details: {
        description: 'Ability to "drill down" on census reports and see who was where on a given day',
        administrative: true,
        categories: [
          'Reporting',
        ],
      },
      can_edit_users: {
        description: 'Ability to add and edit user accounts for all users',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
       can_enable_2fa: {
        description: 'Ability to enable Two-factor authentication for own account',
        administrative: false,
        categories: [
          'Administration',
        ],
      },
      enforced_2fa: {
        description: 'Users with this permission will be unable to login until Two-factor authentication has been enabled',
        administrative: false,
        categories: [
          'Administration',
        ],
      },
      training_required: {
        description: 'Users with this permission will be unable to login until they have completed user training.',
        administrative: false,
        categories: [
          'Administration',
        ],
      },
      can_edit_roles: {
        description: 'Ability to add and remove roles and assign permissions to all roles',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_edit_access_groups: {
        description: 'Ability to add and remove groups and assign entities to all groups',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_audit_users: {
        description: 'Access to the audit logs for users',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_full_ssn: {
        description: 'Ability to see the full Social Security Number for clients',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_full_dob: {
        description: 'Ability to see the Date of Birth for clients',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_hiv_status: {
        description: 'Ability to see the HIV information for clients',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_dmh_status: {
        description: 'Ability to see the Mental Health information for clients',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_imports: {
        description: 'Access to the HUD HMIS import section, must be used in conjunction with access to a data source and assignment of at least one data source.',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_view_projects: {
        description: 'Read-only access to projects.  This also grants access to the list of clients who are or have been enrolled at the projects.  Can be used in conjunction with assignments to data sources, organizations, or projects.',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_projects: {
        description: 'Edit level access for projects and project overrides',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_project_groups: {
        description: 'Setup groupings of projects, mostly for reporting',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_view_organizations: {
        description: 'Read-only access to organization attributes',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_organizations: {
        description: 'Edit level access for organizations and organization overrides',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_data_sources: {
        description: 'Add or Edit data sources, including specifying if it is visible in the window',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_use_strict_search: {
        description: 'Access to the client search screen that requires more exact matching. Assigning "Can Search Window" or "Can View Clients" will take precedence and grant additional access',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_search_window: {
        description: 'Limited access to the data available in the window.  This should be given to any role that has access to client window data. Assigning "Can View Clients" will take precedence and grant additional access',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_client_window: {
        description: 'Ability to drill into the client data from window search results, limited to items available in the window',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_upload_hud_zips: {
        description: 'Access to upload HMIS files from external systems',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_translations: {
        description: 'Ability to translate strings from the default OpenPath language to community specific langauge',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_manage_assessments: {
        description: 'Allows access to the administrative view of ETO TouchPoints',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_manage_client_files: {
        description: 'Ability to view, upload, and delete client files, and control which files are visible in the window',
        administrative: true,
        categories: [
          'Client Extras',
        ],
      },
      can_manage_window_client_files: {
        description: 'Ability to view, upload, and delete files in the window for clients with active confirmed consent or files uploaded by this user',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_see_own_file_uploads: {
        description: 'Access to files this user has uploaded, no access to others.  Usually used for community members who might be collecting files, but shouldn\'t see files provided by others',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_use_separated_consent: {
        description: 'If granted, the user will see a top level consent option for clients.  If unchecked, consent will fall under the files tab',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_manage_config: {
        description: 'Administrative ability to fundamentally change the way various items are calculated and to disable/enable modules',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      # Deprecated TODO: remove references, then remove permission
      can_edit_dq_grades: {
        description: 'Management interface for setup of data quality grading scheme',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_vspdat: {
        description: 'Access to view existing VI-SPDAT records',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_vspdat: {
        description: 'Ability to edit existing VI-SPDAT records',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_submit_vspdat: {
        description: 'Ability to add VI-SPDAT records',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_view_ce_assessment: {
        description: "Access to view existing Coordinated Entry Assessments",
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_ce_assessment: {
        description: "Ability to edit existing Coordinated Entry Assessments",
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_submit_ce_assessment: {
        description: "Ability to add Coordinated Entry Assessments",
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_view_youth_intake: {
        description: 'Access to existing Youth Intake records',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_youth_intake: {
        description: 'Ability to add or edit Youth Intake records',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_delete_youth_intake: {
        description: 'The ability to delete a Youth Intake record',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_view_own_agency_youth_intake: {
        description: 'Access to existing Youth Intake records associated with the User\'s agency',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_own_agency_youth_intake: {
        description: 'Ability to add or edit Youth Intake records associated with the User\'s agency,',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_create_clients: {
        description: 'Given an authoritative data source, users can add clients that don\'t exist in HMIS',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_view_client_history_calendar: {
        description: 'Access to the calendar view of client enrollments',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_view_enrollment_details: {
        description: 'Access to the enrollment details tab.  Users with Can View Clients get this automatically.',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_client_notes: {
        description: 'Ability to edit any client note, used to remove inappropriate notes',
        administrative: true,
        categories: [
          'Client Extras',
        ],
      },
      can_edit_window_client_notes: {
        description: 'Ability to edit any client note in the window, used to remove inappropriate notes',
        administrative: true,
        categories: [
          'Client Extras',
        ],
      },
      can_see_own_window_client_notes: {
        description: 'Access to notes created by the user in the window',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_view_all_window_notes: {
        description: 'User will be able to see notes for any client they can already see, this includes only notes of type Window Note, Alert, or Emergency Contact',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_manage_cohorts: {
        description: 'Ability to create, edit, add and remove clients, and see changes to cohorts',
        administrative: true,
        categories: [
          'Cohorts',
        ],
      },
      can_edit_cohort_clients: {
        description: 'Ability to add and remove clients from cohorts',
        administrative: true,
        categories: [
          'Cohorts',
        ],
      },
      can_edit_assigned_cohorts: {
        description: 'Ability to participate in assigned cohorts',
        administrative: false,
        categories: [
          'Cohorts',
        ],
      },
      can_view_assigned_cohorts: {
        description: 'Read-only access to assigned cohorts',
        administrative: false,
        categories: [
          'Cohorts',
        ],
      },
      can_download_cohorts: {
        description: 'Ability to download the contents of a cohort',
        administrative: false,
        categories: [],
      },
      can_assign_users_to_clients: {
        description: 'Ability to setup user-client relationships',
        administrative: false,
        categories: [
          'Client Extras',
          'Administration',
        ],
      },
      can_view_client_user_assignments: {
        description: 'Read-only access to see user-client relationships',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_export_hmis_data: {
        description: 'When combined with assignment of the appropriate report, allows a user to export HMIS data',
        administrative: false,
        categories: [
          'Reporting',
        ],
      },
      can_export_anonymous_hmis_data: {
        description: 'Fake data exports for developers',
        administrative: true,
        categories: [
          'Reporting',
        ],
      },
      can_confirm_housing_release: {
        description: 'Ability to confirm uploaded housing releases',
        administrative: true,
        categories: [
          'Client Extras',
          'Administration',
        ],
      },
      can_track_anomalies: {
        description: 'Access to identify data anomalies for clients and report them',
        administrative: true,
        categories: [
          'Client Extras',
        ],
      },
      can_view_all_reports: {
        description: 'Access to all reports, regardless of assignment to the user',
        administrative: true,
        categories: [
          'Reporting',
        ],
      },
      can_assign_reports: {
        description: 'Ability to specify which reports other users can see, the other users must have the "Can view assigned reports" permission and reports assigned on the user edit screen',
        administrative: true,
        categories: [
          'Reporting',
          'Administration',
        ],
      },
      can_view_assigned_reports: {
        description: 'Required for access to reports assigned to a user',
        administrative: false,
        categories: [
          'Reporting',
        ],
      },
      can_administer_assigned_reports: {
        description: 'Ability to view and delete reports assigned to other users',
        administrative: true,
        categories: [
          'Reporting',
        ],
      },
      # Removed 11/24/2019 -- no longer in use
      # can_view_project_data_quality_client_details: {
      #   description: 'Drill-down access to client level details on project data quality reports',
      #   administrative: true,
      # },
      # can_manage_organization_users: {
      #   description: 'Can assign users to organizations',
      #   administrative: true,
      # },
      can_view_all_user_client_assignments: {
        description: 'Administrative permission to see all assignments',
        administrative: true,
        categories: [
          'Client Extras',
          'Administration',
        ],
      },
      can_add_administrative_event: {
        description: 'Ability to create administrative events for tracking changes over time',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_see_clients_in_window_for_assigned_data_sources: {
        description: 'This allows a user to see clients in the window where the data source may not be visible in the window.  It is an override that should only be given to users who work at the assigned data source, organization, project.  It must be used in conjunction with assignments on the user edit page.',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_upload_deidentified_hud_hmis_files: {
        description: 'When combined with the ability to upload HUD HMIS files, shows an option to replace PII on ingestion',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_upload_whitelisted_hud_hmis_files: {
        description: 'When combined with the ability to upload HUD HMIS files, imports only clients who have touched a white-listed project',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_edit_warehouse_alerts: {
        description: 'Ability to create and edit warehouse-wide alerts',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_upload_dashboard_extras: {
        description: 'Access to upload the non-HMIS files for use in the Tableau dashboard export',
        administrative: false,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_view_all_secure_uploads: {
        description: 'Access to see all "secure" uploaded files',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_assigned_secure_uploads: {
        description: 'Access to see assigned "secure" uploaded files',
        administrative: false,
        categories: [
          'Administration',
        ],
      },
      can_manage_agency: {
        description: 'Ability to manage users associated with my agency',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_manage_all_agencies: {
        description: 'Ability to manage all agencies',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_clients_with_roi_in_own_coc: {
        description: 'This permission grants access to clients who have a release of information that includes a CoC assigned to the user, or an ROI with no CoC specified',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_edit_help: {
        description: 'Ability to maintain help documents',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_all_hud_reports: {
        description: 'This permission grants access to run all HUD reports, limited by data access assignments.  In addition, this grants access to all HUD reports that have ever been run regardless of access assignments.',
        administrative: true,
        categories: [
          'Reporting',
        ],
      },
      can_view_own_hud_reports: {
        description: 'This permission grants access to run all HUD reports, limited by data access assignments.  Users can only see results for HUD reports they initiated.',
        administrative: false,
        categories: [
          'Reporting',
        ],
      },
      can_view_confidential_enrollment_details: {
        description: 'Anyone with this permission will see the name of confidential projects in locations where it is associated with a client or enrollment.',
        administrative: true,
        categories: [
          'Client Extras',
        ],
      },
      can_manage_ad_hoc_data_sources: {
        description: 'Can this user manage Ad-Hoc Data sources?',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
        ],
      },
      can_view_client_ad_hoc_data_sources: {
        description: 'Can this user see if a client matched Ad-Hoc Data sources?',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_impersonate_users: {
        description: 'Can become any other user.  Anyone with this permission can impersonate any other user and see whatever they would see.',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_delete_projects: {
        description: 'Deleting projects will delete all associated inventory and enrollment information.',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
          'Administration',
        ],
      },
      can_delete_data_sources: {
        description: 'Can delete data sources, organizations or projects. Deleting any of these will delete all associated inventory and enrollment information.',
        administrative: true,
        categories: [
          'Data Sources & Inventory',
          'Administration',
        ],
      },
      can_see_health_emergency: {
        description: 'Ability to see any health emergency information when health emergencies are enabled.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_edit_health_emergency_medical_restriction: {
        description: 'Ability to edit medical restrictions during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_edit_health_emergency_screening: {
        description: 'Ability to edit and delete screening records during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_edit_health_emergency_clinical: {
        description: 'Ability to edit and delete clinical records during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_see_health_emergency_history: {
        description: 'Ability to see client emergency history during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_see_health_emergency_medical_restriction: {
        description: 'Ability to see medical restrictions during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_see_health_emergency_screening: {
        description: 'Ability to see and delete screening records during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_see_health_emergency_clinical: {
        description: 'Ability to see and delete clinical records during a health emergency.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      receives_medical_restriction_notifications: {
        description: 'Email notifications will be sent whenever a medical restriction or test result is added.',
        administrative: false,
        categories: [
          'Health Emergency',
        ],
      },
      can_use_service_register: {
        description: 'Grants the ability to scan individual services for a given program.',
        administrative: false,
        categories: [
          'Client Extras',
        ],
      },
      can_manage_auto_client_de_duplication: {
        description: 'Ability to see statistics around client de-duplication and set the threshold for probabilistic matching.',
        administrative: true,
        categories: [
          'Administration',

        ],
      },
    }
  end

  def self.health_permissions_with_descriptions
    {
      can_administer_health: {
        description: 'Administrative access to all health sections and patient records',
        administrative: true,
        categories: [
        ],
      },
      can_edit_client_health: {
        description: 'Provides the ability to enter data for pilot patients. Pilot Permission',
        administrative: false,
        categories: [
        ],
      },
      can_view_client_health: {
        description: 'Ability to view pilot patient records. Pilot Permission',
        administrative: false,
        categories: [
        ],
      },
      can_view_aggregate_health: {
        description: 'Access to see the claims and ED use data provided from BHCHP',
        administrative: true,
        categories: [
        ],
      },
      can_manage_health_agency: {
        description: 'Ability to add and edit health agency records',
        administrative: true,
        categories: [
        ],
      },
      can_approve_patient_assignments: {
        description: 'Ability to convert patient referrals to patient records and assign patients to agencies',
        administrative: true,
        categories: [
        ],
      },
      can_manage_claims: {
        description: 'Can generate, review, and download claims files',
        administrative: true,
        categories: [
        ],
      },
      can_manage_all_patients: {
        description: 'Ability to claim patient referrals for any agency',
        administrative: true,
        categories: [
        ],
      },
      can_manage_patients_for_own_agency: {
        description: 'Ability to claim patient referrals for an agency, used in conjunction with user-agency assignments',
        administrative: false,
        categories: [
        ],
      },
      can_manage_care_coordinators: {
        description: 'Assign care coordinators to patients',
        administrative: false,
        categories: [
        ],
      },
      can_approve_cha: {
        description: 'Ability to approve Comprehensive Health Assessments',
        administrative: false,
        categories: [
        ],
      },
      can_approve_ssm: {
        description: 'Ability to approve Self-Sufficiency Matrix forms',
        administrative: false,
        categories: [
        ],
      },
      can_approve_release: {
        description: 'Ability to approve release forms',
        administrative: false,
        categories: [
        ],
      },
      can_approve_participation: {
        description: 'Ability to approve participation forms',
        administrative: false,
        categories: [
        ],
      },
      can_edit_all_patient_items: {
        description: 'Unused',
        administrative: true,
        categories: [
        ],
      },
      can_edit_patient_items_for_own_agency: {
        description: 'Edit ability for patient records',
        administrative: false,
        categories: [
        ],
      },
      can_create_care_plans_for_own_agency: {
        description: 'Unused',
        administrative: false,
        categories: [
        ],
      },
      can_view_all_patients: {
        description: 'Unused',
        administrative: true,
        categories: [
        ],
      },
      can_view_patients_for_own_agency: {
        description: 'Allows access to patient records',
        administrative: false,
        categories: [
        ],
      }, # Read-only - not implemented as such yet
      can_add_case_management_notes: {
        description: 'Unused',
        administrative: false,
        categories: [
        ],
      },
      can_manage_accountable_care_organizations: {
        description: 'Administer ACO records',
        administrative: true,
        categories: [
        ],
      },
      can_view_member_health_reports: {
        description: 'Use for downloading individual member reports',
        administrative: true,
        categories: [
        ],
      },
      can_unsubmit_submitted_claims: {
        description: 'Can this user blank out the submitted date on QA, allowing resubmission?',
        administrative: true,
        categories: [
        ],
      },
      can_edit_health_emergency_contact_tracing: {
        description: 'Grants access to the contact tracing section when there is an active health emergency',
        administrative: false,
        categories: [
        ],
      },
    }
  end

  def self.ensure_permissions_exist
    Role.permissions.each do |permission|
      unless ActiveRecord::Base.connection.column_exists?(:roles, permission)
        ActiveRecord::Migration.add_column :roles, permission, :boolean, default: false
      end
    end
  end

end
