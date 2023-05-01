###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
class User < ApplicationRecord
  include UserConcern
  include RailsDrivers::Extensions

  has_many :user_access_controls, dependent: :destroy, inverse_of: :user
  has_many :access_controls, through: :user_access_controls
  has_many :access_groups, through: :access_controls
  has_many :roles, through: :access_controls

  # Healthcare specific
  has_many :user_roles, dependent: :destroy, inverse_of: :user
  has_many :health_roles, through: :user_roles, class_name: 'Role'

  # load a hash of permission names (e.g. 'can_view_all_reports')
  # to a boolean true if the user has the permission through one
  # of their roles
  def load_effective_permissions
    {}.tap do |h|
      roles.each do |role|
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
      joins(:roles).
        where(roles: { permission => true })
    end
  end

  # To fetch the list of AccessGroups that grant a user access to a particular set of projects
  # user.access_group_for?('GrdaWarehouse::Hud::Project', 'can_view_projects')
  # To fetch the list of AccessGroups that grant a user access to clients enrolled at as set of projects
  # user.access_group_for?('GrdaWarehouse::Hud::Project', 'can_view_clients')
  def access_groups_for?(entity_type, perm)
    return false unless entity_type.present? && perm.present?
    return false unless send("#{perm}?")

    role_ids = roles.where(perm => true).pluck(:id)
    access_group_ids = access_controls.where(access_group_id: access_group_ids, role_id: role_ids)

    AccessGroup.where(id: access_group_ids, entity_type: entity_type)
  end

  def related_hmis_user(data_source)
    return unless HmisEnforcement.hmis_enabled?

    Hmis::User.find(id)&.tap { |u| u.update(hmis_data_source_id: data_source.id) }
  end

  # list any cohort this user has some level of access to
  def cohorts
    GrdaWarehouse::Cohort.where(id: access_groups.flat_map(&:cohort_ids))
  end

  # list any project groups the user has some level of access to
  def project_groups
    GrdaWarehouse::ProjectGroup.where(id: access_groups.flat_map(&:project_group_ids))
  end

  # list any data sources the user has some level of access to
  def data_sources
    GrdaWarehouse::DataSource.where(id: access_groups.flat_map(&:data_source_ids))
  end

  # list any reports the user has some level of access to
  def reports
    GrdaWarehouse::DataSource.where(id: access_groups.flat_map(&:report_ids))
  end
end
