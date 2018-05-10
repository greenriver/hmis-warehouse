class Role < ActiveRecord::Base
  has_many :user_roles, dependent: :destroy, inverse_of: :role
  has_many :users, through: :user_roles
  validates :name, presence: true

  def role_name
    name.to_s.humanize.gsub('Dnd', 'DND')
  end

  scope :health, -> do
    where(health_role: true)
  end

  scope :editable, -> do
    where(health_role: false)
  end

  def self.permissions(exclude_health: false)
    perms = [
      :can_view_clients,
      :can_edit_clients,
      :can_view_censuses,
      :can_view_census_details,
      :can_edit_users,
      :can_view_full_ssn,
      :can_view_full_dob,
      :can_view_hiv_status,
      :can_view_dmh_status,
      :can_view_imports,
      :can_edit_roles,
      :can_view_projects,
      :can_edit_projects,
      :can_edit_project_groups,
      :can_view_organizations,
      :can_edit_organizations,
      :can_edit_data_sources,
      :can_search_window,
      :can_view_client_window,
      :can_upload_hud_zips,
      :can_edit_translations,
      :can_manage_assessments,
      :can_edit_anything_super_user,
      :can_manage_client_files,
      :can_manage_window_client_files,
      :can_see_own_file_uploads,
      :can_manage_config,
      :can_edit_dq_grades,
      :can_view_vspdat,
      :can_edit_vspdat,
      :can_submit_vspdat,
      :can_create_clients,
      :can_view_client_history_calendar,
      :can_edit_client_notes,
      :can_edit_window_client_notes,
      :can_see_own_window_client_notes,
      :can_manage_cohorts,
      :can_edit_cohort_clients,
      :can_edit_assigned_cohorts,
      :can_view_assigned_cohorts,
      :can_assign_users_to_clients,
      :can_view_client_user_assignments,
      :can_export_hmis_data,
      :can_confirm_housing_release,
      :can_track_anomalies,
      :can_view_all_reports,
      :can_assign_reports,
      :can_view_assigned_reports,
      :can_view_project_data_quality_client_details,
      :can_manage_organization_users,
      :can_add_administrative_event,
    ]
    perms += self.health_permissions unless exclude_health
    return perms
  end

  def self.health_permissions
    [
      :can_administer_health,
      :can_edit_client_health,
      :can_view_client_health,
      :can_view_aggregate_health,
    ]
  end

  def self.ensure_permissions_exist
    Role.permissions.each do |permission|
      unless ActiveRecord::Base.connection.column_exists?(:roles, permission)
        ActiveRecord::Migration.add_column :roles, permission, :boolean, default: false
      end
    end
  end
end
