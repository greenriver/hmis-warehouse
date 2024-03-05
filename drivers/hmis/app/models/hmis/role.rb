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
        description: 'Grants access to the administration section for HMIS',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Admin Access',
      },
      can_view_project: {
        description: 'Grants access to view the project page. This permission also limits enrollment access. For example, a user with "can view enrollment details" can only view enrollment details at projects that they can view.',
        administrative: false,
        access: [:viewable],
        category: 'Administration',
        sub_category: 'Admin Access',
      },
      can_delete_project: {
        description: 'Grants access to delete projects',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Management',
      },
      can_edit_project_details: {
        description: 'Grants access to edit project details',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Management',
      },
      can_manage_inventory: { # TODO: should be renamed to "can manage units"
        description: 'Ability to manage bed and unit capacity in the project',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Capacity',
      },
      can_manage_incoming_referrals: {
        description: 'Ability to accept/deny incoming referrals in the Project',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Referrals',
      },
      can_manage_outgoing_referrals: {
        description: 'Ability to "refer out" from the Project',
        administrative: false,
        access: [:editable],
        category: 'Projects',
        sub_category: 'Referrals',
      },
      can_manage_denied_referrals: {
        description: 'Ability to manage denied referrals in the Project',
        administrative: false,
        access: [:editable],
        category: 'Projects',
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
        description: 'Ability to audit users',
        administrative: true,
        access: [:viewable],
        category: 'Administration',
        sub_category: 'Users',
      },
      can_edit_organization: {
        description: 'Grants access to edit organizations',
        administrative: false,
        access: [:editable],
        category: 'Organizations',
        sub_category: 'Management',
      },
      can_delete_organization: {
        description: 'Grants access to delete organizations',
        administrative: false,
        access: [:editable],
        category: 'Organizations',
        sub_category: 'Management',
      },
      can_view_clients: {
        description: 'Allow the user to see clients at assigned projects.',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Management',
      },
      can_edit_clients: {
        description: 'Grants access to edit clients',
        administrative: false,
        access: [:editable],
        category: 'Client Access',
        sub_category: 'Management',
      },
      can_delete_clients: {
        description: 'Grants access to delete clients',
        administrative: false,
        access: [:editable],
        category: 'Client Access',
        sub_category: 'Management',
      },
      can_view_full_ssn: {
        description: 'Allow the user to see client\'s full SSN.',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_partial_ssn: {
        description: 'Grants access to view partial SSN',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_dob: {
        description: 'Grants access to view clients\' DOB',
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Sensitive Client Data',
      },
      can_view_hud_chronic_status: {
        description: "Grants access to see Chronic at PIT. Gives you an idea of someones previous enrollments, even ones you can't otherwise see.",
        administrative: false,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Expanded Access',
      },
      can_view_enrollment_details: {
        description: 'Grants access to view enrollment details, including related records such as Assessments, Services, Current Living Situations, and more.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_view_limited_enrollment_details: {
        description: 'Grants access to view limited information about an enrollment, including: entry date, exit date, project name, project type, move-in date, and last bed night date.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_view_open_enrollment_summary: {
        description: 'Grants access to view minimal information (entry date, project name, move-in date) for all open enrollments for a given client, regardless of whether the user can see those other projects.',
        administrative: false,
        access: [:viewable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_edit_enrollments: {
        description: 'Grants access to edit enrollments, including: adding and removing household members, performing assessments, recording services, and creating and editing any other Enrollment-related records.',
        administrative: false,
        access: [:editable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_enroll_clients: {
        description: 'Grants access to enroll clients in the project',
        administrative: false,
        access: [:editable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_delete_enrollments: {
        description: 'Grants the ability to delete enrollments',
        administrative: false,
        access: [:editable],
        category: 'Enrollments',
        sub_category: 'Access',
      },
      can_audit_enrollments: {
        description: 'Access to see who has changed an enrollment record.',
        administrative: true,
        access: [:viewable],
        category: 'Enrollment Administration',
        sub_category: 'Audit History',
      },
      can_delete_assessments: {
        description: 'Ability to delete assessments that have been submitted',
        administrative: false,
        access: [:editable],
        category: 'Assessments Administration',
        sub_category: 'Access',
      },
      can_manage_any_client_files: {
        description: 'Grants the ability to manage anyone\'s client files',
        administrative: false,
        access: [:editable],
        category: 'Files',
        sub_category: 'Management',
      },
      can_manage_own_client_files: {
        description: 'Grants the ability to manage user\'s own client files',
        administrative: false,
        access: [:editable],
        category: 'Files',
        sub_category: 'Management',
      },
      can_view_any_nonconfidential_client_files: {
        description: 'Grants the ability to view non-confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        category: 'Files',
        sub_category: 'Management',
      },
      can_view_any_confidential_client_files: {
        description: 'Grants the ability to view confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        category: 'Files',
        sub_category: 'Sensitive Client Data',
      },
      can_audit_clients: {
        description: 'Access to see who has changed a client record.',
        administrative: false,
        access: [:viewable],
        category: 'Administration',
        sub_category: 'Audit History',
      },
      can_merge_clients: {
        description: 'Grants the ability to merge and split client records',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Client Management',
      },
      can_split_households: {
        description: 'Grants the ability to merge and split households',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Enrollment Management',
      },
      can_transfer_enrollments: {
        description: 'Grants the ability to transfer enrollments between projects',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Enrollment Management',
      },
      can_configure_data_collection: {
        description: 'Grants access to configuration tool for forms, services, and assessments',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Configuration',
      },
      can_manage_scan_cards: {
        description: 'Grants the ability to create and deactivate Scan Cards',
        administrative: true,
        access: [:editable],
        category: 'Administration',
        sub_category: 'Scan Cards',
      },
      can_view_client_alerts: {
        description: 'Grants the ability to view Client Alerts',
        administrative: true,
        access: [:viewable],
        category: 'Client Access',
        sub_category: 'Alerts',
      },
      can_manage_client_alerts: {
        description: 'Grants the ability to manage Client Alerts',
        administrative: true,
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
