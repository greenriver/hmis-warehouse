###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Role < ::ApplicationRecord
  self.table_name = :hmis_roles
  # Warehouse roles do not have a paper trail, so neither do these

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
    permissions_with_descriptions[permission][:categories] rescue [] # rubocop:disable Style/RescueModifier
  end

  def self.administrative?(permission:)
    permissions_with_descriptions[permission][:administrative] rescue true # rubocop:disable Style/RescueModifier
  end

  def self.permission_categories
    permissions_with_descriptions.values.map { |perm| perm[:categories] }.flatten.uniq
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

  def self.permissions_with_descriptions
    {
      can_administer_hmis: {
        description: 'Grants access to the administration section for HMIS',
        administrative: true,
        access: [:editable],
        categories: [
          'Administration',
        ],
      },
      can_view_project: {
        description: 'Grants access to view the project page. This permission also limits enrollment access. For example, a user with "can view enrollment details" can only view enrollment details at projects that they can view.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Projects',
        ],
      },
      can_delete_project: {
        description: 'Grants access to delete projects',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_edit_project_details: {
        description: 'Grants access to edit project details',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_manage_inventory: { # TODO: should be renamed to "can manage units"
        description: 'Ability to manage bed and unit capacity in the project',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_manage_incoming_referrals: {
        description: 'Ability to accept/deny incoming referrals in the Project',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_manage_outgoing_referrals: {
        description: 'Ability to "refer out" from the Project',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_manage_denied_referrals: {
        description: 'Ability to manage denied referrals in the Project',
        administrative: false,
        access: [:editable],
        categories: [
          'Projects',
        ],
      },
      can_impersonate_users: {
        description: 'Ability to impersonate other users',
        administrative: true,
        access: [:editable],
        categories: [
          'Users',
        ],
      },
      can_edit_organization: {
        description: 'Grants access to edit organizations',
        administrative: false,
        access: [:editable],
        categories: [
          'Organizations',
        ],
      },
      can_delete_organization: {
        description: 'Grants access to delete organizations',
        administrative: false,
        access: [:editable],
        categories: [
          'Organizations',
        ],
      },
      can_view_clients: {
        description: 'Allow the user to see clients at assigned projects.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Client Access',
        ],
      },
      can_edit_clients: {
        description: 'Grants access to edit clients',
        administrative: false,
        access: [:editable],
        categories: [
          'Client Access',
        ],
      },
      can_delete_clients: {
        description: 'Grants access to delete clients',
        administrative: false,
        access: [:editable],
        categories: [
          'Client Access',
        ],
      },
      can_view_full_ssn: {
        description: 'Allow the user to see client\'s full SSN.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Client Details',
        ],
      },
      can_view_partial_ssn: {
        description: 'Grants access to view partial SSN',
        administrative: false,
        access: [:viewable],
        categories: [
          'Client Access',
        ],
      },
      can_view_dob: {
        description: 'Grants access to view clients\' DOB',
        administrative: false,
        access: [:viewable],
        categories: [
          'Client Access',
        ],
      },
      can_view_hud_chronic_status: {
        description: "Grants access to see Chronic at PIT. Gives you an idea of someones previous enrollments, even ones you can't otherwise see.",
        administrative: false,
        access: [:viewable],
        categories: [
          'Client Access',
        ],
      },
      can_view_enrollment_details: {
        description: 'Grants access to view enrollment details, including related records such as Assessments, Services, Current Living Situations, and more.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Enrollments',
        ],
      },
      can_view_open_enrollment_summary: {
        description: 'Grants access to view minimal information (entry date, project name, move-in date) for all open enrollments for a given client, regardless of whether the user can see those other projects.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Enrollments',
        ],
      },
      can_edit_enrollments: {
        description: 'Grants access to edit enrollments, including: adding and removing household members, performing assessments, recording services, and creating and editing any other Enrollment-related records.',
        administrative: false,
        access: [:editable],
        categories: [
          'Enrollments',
        ],
      },
      can_enroll_clients: {
        description: 'Grants access to enroll clients in the project',
        administrative: false,
        access: [:editable],
        categories: [
          'Enrollments',
        ],
      },
      can_delete_enrollments: {
        description: 'Grants the ability to delete enrollments',
        administrative: false,
        access: [:editable],
        categories: [
          'Enrollments',
        ],
      },
      can_delete_assessments: {
        description: 'Ability to delete assessments that have been submitted',
        administrative: false,
        access: [:editable],
        categories: [
          'Assessments',
        ],
      },
      can_manage_any_client_files: {
        description: 'Grants the ability to manage anyone\'s client files',
        administrative: false,
        access: [:editable],
        categories: [
          'Files',
        ],
      },
      can_manage_own_client_files: {
        description: 'Grants the ability to manage user\'s own client files',
        administrative: false,
        access: [:editable],
        categories: [
          'Files',
        ],
      },
      can_view_any_nonconfidential_client_files: {
        description: 'Grants the ability to view non-confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        categories: [
          'Files',
        ],
      },
      can_view_any_confidential_client_files: {
        description: 'Grants the ability to view confidential client files uploaded by anyone',
        administrative: false,
        access: [:viewable],
        categories: [
          'Files',
        ],
      },
      can_audit_clients: {
        description: 'Access to see who has changed a client record.',
        administrative: false,
        access: [:viewable],
        categories: [
          'Audit History',
        ],
      },
      can_merge_clients: {
        description: 'Grants the ability to merge and split client records',
        administrative: true,
        access: [:editable],
        categories: [
          'Administrative',
          'Client Access',
        ],
      },
      can_split_households: {
        description: 'Grants the ability to merge and split households',
        administrative: true,
        access: [:editable],
        categories: [
          'Administrative',
          'Enrollments',
        ],
      },
      can_transfer_enrollments: {
        description: 'Grants the ability to transfer enrollments between projects',
        administrative: true,
        access: [:editable],
        categories: [
          'Administrative',
          'Enrollments',
        ],
      },
    }
  end
end
