###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Role < ::ApplicationRecord
  self.table_name = :hmis_roles
  # Warehouse roles do not have a paper trail, so neither do these

  has_many :access_controls, class_name: '::Hmis::AccessControl', inverse_of: :role
  has_many :user_access_controls, through: :access_controls
  has_many :users, through: :user_access_controls

  # has_many :user_hmis_data_source_roles, class_name: '::Hmis::UserHmisDataSourceRole'
  # has_many :users, through: :user_hmis_data_source_roles, source: :user

  scope :with_all_permissions, ->(*perms) do
    where(**perms.map { |p| [p, true] }.to_h)
  end

  scope :with_any_permissions, ->(*perms) do
    scope = self
    perms.map { |p| scope = scope.or(Hmis::Role.where(p => true)) }
    scope
  end

  scope :with_editable_permissions, -> do
    with_any_permissions(
      :can_delete_assigned_project_data,
      :can_administer_hmis,
      :can_delete_enrollments,
    )
  end

  scope :with_viewable_permissions, -> do
    with_any_permissions(
      :can_view_full_ssn,
      :can_view_clients,
    )
  end

  def administrative?
    self.class.permissions_with_descriptions.each do |permission, description|
      return true if description[:administrative] && self[permission]
    end
    false
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

  def self.permissions_with_descriptions
    {
      can_administer_hmis: {
        description: 'Grants access to the administration section for HMIS',
        administrative: true,
        categories: [
          'Administration',
        ],
      },
      can_view_full_ssn: {
        description: 'Allow the user to see client\'s full SSN.',
        administrative: false,
        categories: [
          'Client Details',
        ],
      },
      can_view_clients: {
        description: 'Allow the user to see clients at assigned projects.',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
      can_delete_assigned_project_data: {
        description: 'Grants access to delete project related data for projects the user can see',
        administrative: false,
        categories: [
          'Projects',
        ],
      },
      can_delete_enrollments: {
        description: 'Grants the ability to delete enrollments for clients the user has access to',
        administrative: false,
        categories: [
          'Client Access',
        ],
      },
    }
  end
end
