###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE:
# r = Hmis::Role.create(name: 'test')
# u = Hmis::User.first; u.hmis_data_source_id = 3
# g = Hmis::AccessGroup.create(name: 'test')
# ac = u.access_controls.create(role: r, access_group: g)
# u.user_access_controls.create(user: u, access_control: ac)
# u.can_view_full_ssn?
require 'memery'
class Hmis::User < ApplicationRecord
  include UserConcern
  include HasRecentItems
  self.table_name = :users

  has_many :user_access_controls, class_name: '::Hmis::UserAccessControl', dependent: :destroy, inverse_of: :user
  has_many :access_controls, through: :user_access_controls
  has_many :access_groups, through: :access_controls
  has_many :roles, through: :access_controls

  has_recent :clients, Hmis::Hud::Client
  has_recent :projects, Hmis::Hud::Project
  attr_accessor :hmis_data_source_id # stores the data_source_id of the currently logged in HMIS

  def skip_session_limitable?
    true
  end

  # load a hash of global permission names (e.g. 'can_view_all_reports')
  # to a boolean true if the user has the permission through one
  # of their roles
  def load_effective_permissions
    {}.tap do |h|
      roles.each do |role|
        ::Hmis::Role.permissions.each do |permission|
          h[permission] ||= role.send(permission)
        end
      end
    end
  end

  # define helper methods for looking up if this
  # user has an permission through one of its roles
  ::Hmis::Role.permissions.each do |permission|
    define_method(permission) do
      @permissions ||= load_effective_permissions
      @permissions[permission]
    end

    # Methods for determining if a user has permission
    # e.g. the_user.can_administer_health?
    define_method("#{permission}?") do
      send(permission)
    end

    define_method("#{permission}_for?") do |entity|
      # Just return false if we don't have this permission at all for anything
      return false unless send("#{permission}?")

      # Return true if we should use global permissions for the entity, since we just did the global permission check
      return true if use_global_permissions_for_entity?(entity)

      base_entities = permissions_base_for_entity(entity)

      # Raise if there's no permissions base for the entity we're checking permissions on
      raise "Invalid entity '#{entity.class.name}' for permission '#{permission}'" if base_entities.nil?

      # No permissions on this entity if there's nothing that would grant it permissions
      return false unless base_entities.present?

      access_group_ids = Hmis::GroupViewableEntity.includes_entities(base_entities).pluck(:access_group_id)
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

  def lock_access!(opts = {})
    super opts.merge({ send_instructions: false })
  end

  # A permissions base is an entity or entities that grant permissions on the given entity. This can be the entity
  # itself in the case of projects, or can be another entity in the case of files, which are granted permissions through
  # their client or their enrollment. A result of nil indicates that there is no permissions base for the given entity.
  # If there is a permissions base, the result will be zero or more entities to use as a permissions base. If the result
  # is no entities, it means that the entity has a permissions base, but no entities that act as that base are present.
  # For example, if a client is granted permissions through enrollments but has no enrollments, it would return no
  # entities.
  private def permissions_base_for_entity(entity)
    return unless entity.present?

    return entity.projects_including_wip if entity.is_a? Hmis::Hud::Client
    return entity if entity.is_a? Hmis::Hud::Organization
    return entity if entity.is_a? Hmis::Hud::Project

    return permissions_base_for_entity(entity.enrollment || entity.client) if entity.is_a? Hmis::File

    return entity.project if entity.respond_to? :project

    nil
  end

  private def use_global_permissions_for_entity?(entity)
    return true if entity.is_a?(Hmis::Hud::Client) && !entity.enrolled?
    return true if entity.is_a?(Hmis::File) && !entity.client.enrolled?

    return false
  end

  private def check_permissions_with_mode(*permissions, mode: :any)
    method_name = mode == :all ? :all? : :any?
    permissions.send(method_name) { |perm| yield(perm) }
  end

  def permission?(permission)
    respond_to?(permission) ? send(permission) : false
  end

  def permission_for?(entity, permission)
    method_name = "#{permission}_for?".to_sym
    respond_to?(method_name) ? send(method_name, entity) : false
  end

  def permissions?(*permissions, mode: :any)
    check_permissions_with_mode(*permissions, mode: mode) { |perm| permission?(perm) }
  end

  def permissions_for?(entity, *permissions, mode: :any)
    check_permissions_with_mode(*permissions, mode: mode) { |perm| permission_for?(entity, perm) }
  end

  def entities_with_permissions(model, *permissions, **kwargs)
    model.where(
      id: Hmis::GroupViewableEntity.where(
        access_group_id: access_groups.with_permissions(*permissions, **kwargs).pluck(:id),
        entity_type: model.sti_name,
      ).select(:entity_id),
    )
  end

  private def viewable(model)
    entities_with_permissions(model, *Hmis::Role.permissions_for_access(:viewable), mode: 'any')
  end

  def viewable_data_sources
    viewable GrdaWarehouse::DataSource
  end

  def viewable_organizations
    viewable Hmis::Hud::Organization
  end

  def viewable_projects
    viewable Hmis::Hud::Project
  end

  def viewable_project_access_groups
    viewable GrdaWarehouse::ProjectAccessGroup
  end

  def viewable_project_ids
    @viewable_project_ids ||= Hmis::Hud::Project.viewable_by(self).pluck(:id)
  end

  private def cached_viewable_project_ids(force_calculation: false)
    key = [self.class.name, __method__, id]
    Rails.cache.delete(key) if force_calculation
    Rails.cache.fetch(key, expires_in: 1.minutes) do
      Hmis::Hud::Project.viewable_by(self).pluck(:id).to_set
    end
  end

  private def editable(model)
    model.where(
      id: Hmis::GroupViewableEntity.where(
        access_group_id: access_groups.editable.pluck(:id),
        entity_type: model.sti_name,
      ).select(:entity_id),
    )
  end

  def editable_data_sources
    editable GrdaWarehouse::DataSource
  end

  def editable_organizations
    editable Hmis::Hud::Organization
  end

  def editable_projects
    editable Hmis::Hud::Project
  end

  def editable_project_access_groups
    editable GrdaWarehouse::ProjectAccessGroup
  end

  def editable_project_ids
    @editable_project_ids ||= Hmis::Hud::Project.viewable_by(self).pluck(:id)
  end
end
