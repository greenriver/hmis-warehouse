class Role < ActiveRecord::Base
  has_many :user_roles, dependent: :destroy, inverse_of: :role
  has_many :users, through: :user_roles
  validates :name, presence: true
  
  def role_name
    name.to_s.humanize.gsub 'Dnd', 'DND'
  end

  def self.permissions
    [
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
      :can_view_organizations,
      :can_view_client_window,
      :can_upload_hud_zips,
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
