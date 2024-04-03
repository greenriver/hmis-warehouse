###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Role < ::ApplicationRecord
  self.table_name = :hmis_roles
  acts_as_paranoid
  has_paper_trail

  has_many :access_controls, class_name: '::Hmis::AccessControl', inverse_of: :role
  has_many :users, through: :access_controls

  scope :with_all_permissions, ->(*perms) do
    where(**perms.map { |p| [p, true] }.to_h)
  end

  scope :with_any_permissions, ->(*perms) do
    rt = Hmis::Role.arel_table
    where_clause = perms.map { |perm| rt[perm.to_sym].eq(true) }.reduce(:or)
    where(where_clause)
  end

  scope :with_permissions, ->(*perms, mode: :any) do
    case mode.to_sym
    when :any
      with_any_permissions(*perms)
    when :all
      with_all_permissions(*perms)
    else
      raise "Invalid permission mode: #{mode}"
    end
  end

  scope :with_editable_permissions, -> do
    with_any_permissions(*permissions_for_access(:editable))
  end

  scope :with_viewable_permissions, -> do
    with_any_permissions(*permissions_for_access(:viewable))
  end

  def administrative?
    self.class.permissions_with_descriptions.each do |permission, description|
      return true if description[:administrative] && self[permission]
    end
    false
  end

  # @param permission [Symbol]
  # @return [Boolean]
  def grants?(permission)
    raise "unknown permission #{permission.inspect}" unless self.class.permissions_with_descriptions.key?(permission)

    send(permission) || false
  end

  def self.description_for(permission:)
    permissions_with_descriptions[permission][:description] rescue '' # rubocop:disable Style/RescueModifier
  end

  def self.category_for(permission:)
    permissions_with_descriptions[permission][:category] rescue [] # rubocop:disable Style/RescueModifier
  end

  def self.administrative?(permission:)
    permissions_with_descriptions[permission][:administrative] rescue true # rubocop:disable Style/RescueModifier
  end

  def self.permission_categories
    permissions_with_descriptions.map { |_perm_key, perm| perm[:category] }
  end

  def self.permissions(*) # * for backwards compatibility in the view
    permissions_with_descriptions.keys
  end

  def self.ensure_permissions_exist
    permissions.each do |permission|
      ActiveRecord::Migration.add_column(table_name, permission, :boolean, default: false) unless ActiveRecord::Base.connection.column_exists?(table_name, permission)
    end
  end

  def self.permissions_for_access(access)
    permissions_with_descriptions.select { |_k, attrs| attrs[:access].include?(access) }.keys
  end

  # Permissions that may be used globally (data access does not need to be specified)
  def self.global_permissions
    permissions_with_descriptions.select { |_k, attrs| attrs[:global] }.keys
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
      can_administer_hmis: {
        description: 'Ability to manage permissions and data access for the HMIS. Grants access to HMIS Admin section of the Warehouse.',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Admin Tools',
      },
      can_view_project: {
        description: 'Access to view the Project Dashboard. This permission also limits enrollment access. For example, a user with "can view enrollment details" can only view enrollment details at projects that they can view.',
        administrative: false,
        access: [:viewable],
        category: 'Project Access',
        sub_category: 'Access',
      },
      can_delete_project: {
        administrative: true,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Management',
      },
      can_edit_project_details: {
        description: 'Ability to create new projects & edit details for existing projects',
        administrative: true,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Management',
      },
      can_manage_inventory: { # TODO: should be renamed to "can manage units"
        description: 'Ability to manage bed and unit capacity in the project',
        administrative: false,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Management',
      },
      can_manage_incoming_referrals: {
        description: 'Ability to accept/deny incoming referrals in the Project',
        administrative: false,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Referrals',
      },
      can_manage_outgoing_referrals: {
        description: 'Ability to "refer out" from the Project',
        administrative: false,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Referrals',
      },
      can_manage_denied_referrals: {
        description: 'Ability to manage denied referrals in the Project',
        administrative: true,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Referrals',
      },
      can_impersonate_users: {
        description: 'Ability to impersonate other users',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Users',
      },
      can_audit_users: {
        description: 'View audit trail of each HMIS activity for each user. Includes changes that they made, as well as Client records that they accessed.',
        administrative: true,
        access: [:viewable],
        category: 'Administration',
        sub_category: 'Users',
      },
      can_edit_organization: {
        description: 'Ability to create and edit organization records',
        administrative: false,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Organizations',
      },
      can_delete_organization: {
        administrative: true,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Organizations',
      },
      can_view_clients: {
        description: 'Access to view clients at assigned projects',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Access',
      },
      can_edit_clients: {
        description: 'Ability to create clients & edit client demographics',
        administrative: false,
        access: [:editable],
        category: 'Client Access',
        sub_category: 'Access',
      },
      can_delete_clients: {
        administrative: true,
        access: [:editable],
        category: 'Client Access',
        sub_category: 'Access',
      },
      can_view_client_name: {
        description: 'Access to view Client Name.',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_client_contact_info: {
        description: 'Access to view client contact info: addresses, phone numbers, emails.',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_full_ssn: {
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_partial_ssn: {
        description: 'Access to view last 4 digits of SSN',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_dob: {
        description: 'Access to view Date of Birth. (Note: client\'s age is always visible, even if this permission is not checked).',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_hud_chronic_status: {
        description: "Access to view 'Chronic at PIT' status on the Client Dashboard. This field gives you an idea of someones previous enrollments, even ones you can't otherwise see.",
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Expanded Access',
      },
      can_view_enrollment_details: {
        description: 'When granted in conjunction with "Can View Project," grants access to view the full Enrollment Dashboard. Includes all related records such as Assessments, Services, Current Living Situations, and more.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollment Access',
        sub_category: 'Access',
      },
      can_view_limited_enrollment_details: {
        description: 'Access to view limited information about an enrollment, including: entry date, exit date, project name, project type, move-in date, and last bed night date.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollment Access',
        sub_category: 'Access',
      },
      can_view_open_enrollment_summary: {
        description: 'Access to view minimal information for ALL open enrollments for a given client, regardless of whether the user can see those other projects.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollment Access',
        sub_category: 'Expanded Access',
      },
      can_edit_enrollments: {
        description: 'Ability to edit enrollment details. This includes the ability to create/edit assessments, services, living situations, and other Enrollment-related records.',
        administrative: false,
        access: [:editable],
        category: 'Enrollment Access',
        sub_category: 'Access',
      },
      can_enroll_clients: {
        description: 'Ability to enroll new or existing clients into the project. (Note: \'Can edit clients\' is required for creating new client records.)',
        administrative: false,
        access: [:editable],
        category: 'Project Access',
        sub_category: 'Access',
      },
      can_delete_enrollments: {
        description: 'Ability to delete enrollments. (Note: users with Edit-access can delete "incomplete" enrollments even if this box is not checked).',
        administrative: true,
        access: [:editable],
        category: 'Enrollment Access',
        sub_category: 'Deletion',
      },
      can_audit_enrollments: {
        description: 'View audit history for the Enrollment, and associated records, on the Enrollment Dashboard',
        administrative: true,
        access: [:viewable],
        category: 'Enrollment Access',
        sub_category: 'History',
      },
      can_delete_assessments: {
        description: 'Ability to delete assessments that have been submitted. (Note: users with Edit-access can delete "in-progress" assessments even if this box is not checked).',
        administrative: true,
        access: [:editable],
        category: 'Enrollment Access',
        sub_category: 'Deletion',
      },
      can_manage_any_client_files: {
        description: 'Access to upload, edit, and delete any client files that I can see',
        administrative: false,
        access: [:editable],
        category: 'Client Files',
        sub_category: 'Management',
      },
      can_manage_own_client_files: {
        description: 'Access to upload, edit, and delete client files that I uploaded',
        administrative: false,
        access: [:editable],
        category: 'Client Files',
        sub_category: 'Management',
      },
      can_view_any_nonconfidential_client_files: {
        description: 'Access to view non-confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        category: 'Client Files',
        sub_category: 'Access',
      },
      can_view_any_confidential_client_files: {
        description: 'Access to view confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        category: 'Client Files',
        sub_category: 'Access',
      },
      can_audit_clients: {
        description: 'View audit history for client on the Client Dashboard',
        administrative: true,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'History',
      },
      can_merge_clients: {
        description: 'Ability to merge and split client records',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Client Management',
      },
      can_split_households: {
        description: 'Ability to merge and split households',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Enrollment Management',
      },
      can_transfer_enrollments: {
        description: 'Ability to transfer enrollments between projects',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Enrollment Management',
      },
      can_configure_data_collection: {
        description: 'Ability to configure custom assessments, services, auto-exit, and other application rules',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Admin Tools',
      },
      can_manage_scan_cards: {
        description: 'Ability to create and deactivate Scan Cards',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Scan Cards',
      },
      can_view_client_alerts: {
        description: 'Access to view Client Alerts',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Alerts',
      },
      can_manage_client_alerts: {
        description: 'Ability to create, edit, and delete Client Alerts',
        administrative: false,
        access: [:editable],
        category: 'Client Access',
        sub_category: 'Alerts',
      },
      can_manage_external_form_submissions: {
        description: 'Grants the ability to manage public form submissions',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Access',
      },
    }
  end
end
