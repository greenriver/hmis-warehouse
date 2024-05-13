###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
class User < ApplicationRecord
  include Memery
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

  # TODO: START_ACL remove when ACL transition complete
  has_many :access_group_members, dependent: :destroy, inverse_of: :user
  has_many :access_groups, through: :access_group_members
  # END_ACL

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

    # Provide a scope for each permission to get any user who qualifies
    # e.g. User.can_administer_health
    scope permission, -> do
      joins(:legacy_roles).
        merge(Role.where(permission => true))
    end
  end

  memoize def project_permission_by_id?(permission:, project_id:)
    project_ids = GrdaWarehouse::Hud::Project.project_ids_viewable_by(self, permission: permission)
    project_ids(permission).include?(project_id)
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

  def populate_external_reporting_permissions!
    # Projects
    permission = :can_view_assigned_reports
    ids = GrdaWarehouse::Hud::Project.viewable_by(self, permission: permission).pluck(:id)
    batch = ids.uniq.map do |item_id|
      GrdaWarehouse::ExternalReportingProjectPermission.new(user_id: id, email: email, project_id: item_id, permission: permission)
    end
    GrdaWarehouse::ExternalReportingProjectPermission.transaction do
      GrdaWarehouse::ExternalReportingProjectPermission.where(user_id: id).delete_all
      GrdaWarehouse::ExternalReportingProjectPermission.import(batch)
    end

    # Cohorts
    ids = GrdaWarehouse::Cohort.viewable_by(self).pluck(:id)
    batch = ids.uniq.map do |item_id|
      GrdaWarehouse::ExternalReportingCohortPermission.new(user_id: id, email: email, cohort_id: item_id, permission: :can_view_cohorts)
    end
    GrdaWarehouse::ExternalReportingCohortPermission.transaction do
      GrdaWarehouse::ExternalReportingCohortPermission.where(user_id: id).delete_all
      GrdaWarehouse::ExternalReportingCohortPermission.import(batch)
    end
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
  # To fetch the list of Controls that grant a user access to a particular set of projects
  # user.access_group_for?('GrdaWarehouse::Hud::Project', 'can_view_projects')
  # To fetch the list of Controls that grant a user access to clients enrolled at as set of projects
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

  def any_hmis_access?
    return false unless HmisEnforcement.hmis_enabled?

    Hmis::UserGroupMember.where(user_id: id).exists? # belongs to any HMIS user groups
  end

  # list any cohort this user has some level of access to
  def cohorts
    GrdaWarehouse::Cohort.where(id: ids_for_relations(:cohort_ids))
  end

  # list any project groups the user has some level of access to
  def project_groups
    GrdaWarehouse::ProjectGroup.where(id: ids_for_relations(:project_group_ids))
  end

  # list any data sources the user has some level of access to
  def data_sources
    GrdaWarehouse::DataSource.where(id: ids_for_relations(:data_source_ids))
  end

  # list any reports the user has some level of access to
  def reports
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(id: ids_for_relations(:report_ids))
  end

  # memoize some id lookups to prevent N+1s
  private def ids_for_relations(relation)
    @ids_for_relations ||= {}
    return @ids_for_relations[relation] if @ids_for_relations[relation].present?

    # START_ACL cleanup after ACL migration is complete
    @ids_for_relations[relation] = if using_acls?
      collections.flat_map(&relation)
    else
      access_groups.flat_map(&relation)
    end
    # END_ACL
    @ids_for_relations[relation]
  end

  def unique_role_names
    return legacy_roles.map(&:name).uniq unless using_acls?

    roles.map(&:name).uniq
  end

  memoize def global_auth_policy
    GrdaWarehouse::AuthPolicies::GlobalPolicy.new(user: self)
  end

  memoize def project_auth_policy(project_or_project_id)
    project_id = case project_or_project_id
    when GrdaWarehouse::Hud::Project
      project_or_project_id.id
    when Integer, String
      project_or_project_id
    else
      raise "unknown entity #{record}"
    end
    GrdaWarehouse::AuthPolicies::ProjectPolicy.new(user: self, project_id: project_id)
  end
end
