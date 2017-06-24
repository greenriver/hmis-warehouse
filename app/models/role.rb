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
      :can_view_reports,
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
      :can_edit_project_groups,
      :can_view_organizations,
      :can_view_client_window,
      :can_upload_hud_zips,
      :can_edit_anything_super_user,
    ] 
    perms += self.health_permissions unless exclude_health
    return perms
  end

  def self.health_permissions
    [
      :can_administer_health,
      :can_edit_client_health,
      :can_view_client_health,
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
