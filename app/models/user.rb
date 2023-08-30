###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
class User < ApplicationRecord
  include UserConcern
  include RailsDrivers::Extensions

  USER_PERMISSION_PREFIX = 'user_permissions'
  USER_PROJECT_ID_PREFIX = "#{USER_PERMISSION_PREFIX}_project_ids".freeze
  EXPIRY_MINUTES = 5

  has_many :user_group_members, dependent: :destroy, inverse_of: :user
  has_many :user_groups, through: :user_group_members
  has_many :access_controls, through: :user_groups
  has_many :collections, through: :access_controls
  has_many :roles, through: :access_controls

  has_many :user_roles, dependent: :destroy, inverse_of: :user
  has_many :legacy_roles, through: :user_roles # TODO: START_ACL remove after ACL migration is complete
  has_many :health_roles, -> { health }, through: :user_roles

  # load a hash of permission names (e.g. 'can_view_all_reports')
  # to a boolean true if the user has the permission through one
  # of their roles
  def load_effective_permissions
    {}.tap do |h|
      role_source = if using_acls? then roles else legacy_roles end
      role_source.each do |role|
        Role.permissions(exclude_health: true).each do |permission|
          h[permission] ||= role.send(permission)
        end
      end
    end
  end

  # Health related permissions are tied to roles through user_roles
  def load_health_effective_permissions
    {}.tap do |h|
      health_roles.each do |role|
        Role.health_permissions.each do |permission|
          h[permission] ||= role.send(permission)
        end
      end
    end
  end

  # define helper methods for looking up if this
  # user has an permission through one of its roles
  Role.permissions.each do |permission|
    define_method(permission) do
      @permissions ||= load_effective_permissions.merge(load_health_effective_permissions)
      @permissions[permission]
    end

    # Methods for determining if a user has permission
    # e.g. the_user.can_administer_health?
    define_method("#{permission}?") do
      send(permission)
    end

    define_method("#{permission}_for?") do |entity|
      return false unless send("#{permission}?")

      access_group_ids = GroupViewableEntity.includes_entity(entity).pluck(:access_group_id)

      raise "Invalid entity '#{entity.class.name}'" if access_group_ids.nil?

      role_ids = roles.where(permission => true).pluck(:id)

      access_controls.where(access_group_id: access_group_ids, role_id: role_ids).exists?
    end

    # Provide a scope for each permission to get any user who qualifies
    # e.g. User.can_administer_health
    scope permission, -> do
      joins(:legacy_roles).
        where(roles: { permission => true })
    end
  end

  def user_permission_prefix
    "#{USER_PERMISSION_PREFIX}_user_#{id}"
  end

  def collections_for_permission(permission)
    scope = collections.joins(access_controls: :role).merge(Role.where(permission => true))
    return scope.pluck(:id) if Rails.env.test?

    Rails.cache.fetch("#{user_permission_prefix}_entity_groups_#{permission}", expires_in: EXPIRY_MINUTES.minutes) do
      scope.pluck(:id)
    end
  end

  def user_project_id_prefix
    "#{USER_PROJECT_ID_PREFIX}_user_#{id}"
  end

  def viewable_project_ids(context)
    return GrdaWarehouse::Hud::Project.project_ids_viewable_by(self, permission: context) if Rails.env.test?

    Rails.cache.fetch("#{user_project_id_prefix}_#{context}", expires_in: EXPIRY_MINUTES.minutes) do
      GrdaWarehouse::Hud::Project.project_ids_viewable_by(self, permission: context)
    end
  end

  def editable_project_ids
    return GrdaWarehouse::Hud::Project.project_ids_editable_by(self) if Rails.env.test?

    Rails.cache.fetch("#{user_project_id_prefix}_editable", expires_in: EXPIRY_MINUTES.minutes) do
      GrdaWarehouse::Hud::Project.project_ids_editable_by(self)
    end
  end

  def self.clear_cached_permissions
    Rails.cache.delete_matched("#{USER_PERMISSION_PREFIX}*")
  end

  def clear_cached_permissions
    Rails.cache.delete_matched("#{user_permission_prefix}*")
  end

  def self.clear_cached_project_ids
    Rails.cache.delete_matched("#{USER_PROJECT_ID_PREFIX}*")
  end

  def clear_cached_project_ids
    Rails.cache.delete_matched("#{user_project_id_prefix}*")
  end
  # To fetch the list of Controlss that grant a user access to a particular set of projects
  # user.access_group_for?('GrdaWarehouse::Hud::Project', 'can_view_projects')
  # To fetch the list of Controlss that grant a user access to clients enrolled at as set of projects
  # user.access_group_for?('GrdaWarehouse::Hud::Project', 'can_view_clients')
  # def access_groups_for?(entity_type, perm)
  #   return false unless entity_type.present? && perm.present?
  #   return false unless send("#{perm}?")

  #   role_ids = roles.where(perm => true).pluck(:id)
  #   acs = access_controls.where(access_group_id: access_group_ids, role_id: role_ids)
  #   FIXME, this isn't quite right yet
  #   Controls.where(id: acs.pluck(:access_group_id), entity_type: entity_type)
  # end
  def related_hmis_user(data_source)
    return unless HmisEnforcement.hmis_enabled?

    Hmis::User.find(id)&.tap { |u| u.update(hmis_data_source_id: data_source.id) }
  end

  # list any cohort this user has some level of access to
  def cohorts
    # START_ACL cleanup after ACL migration is complete
    if using_acls?
      GrdaWarehouse::Cohort.where(id: collections.flat_map(&:cohort_ids))
    else
      GrdaWarehouse::Cohort.where(id: access_groups.flat_map(&:cohort_ids))
    end
    # END_ACL
  end

  # list any project groups the user has some level of access to
  def project_groups
    # START_ACL cleanup after ACL migration is complete
    if using_acls?
      GrdaWarehouse::ProjectGroup.where(id: collections.flat_map(&:project_group_ids))
    else
      GrdaWarehouse::ProjectGroup.where(id: access_groups.flat_map(&:project_group_ids))
    end
    # END_ACL
  end

  # list any data sources the user has some level of access to
  def data_sources
    # START_ACL cleanup after ACL migration is complete
    if using_acls?
      GrdaWarehouse::DataSource.where(id: collections.flat_map(&:data_source_ids))
    else
      GrdaWarehouse::DataSource.where(id: access_groups.flat_map(&:data_source_ids))
    end
    # END_ACL
  end

  # list any reports the user has some level of access to
  def reports
    # START_ACL cleanup after ACL migration is complete
    if using_acls?
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(id: collections.flat_map(&:report_ids))
    else
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(id: access_groups.flat_map(&:report_ids))
    end
    # END_ACL
  end
end
