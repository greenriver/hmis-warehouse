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

      loader = entity_access_loader(entity)
      if loader.is_a?(Symbol)
        # loader is an alias
        loader = entity_access_loader(entity.send(loader))
      end
      loader.fetch_one(entity, permission)
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

  # The access loader for an entity, or an alias on entity
  # that should be called
  # @return [Hmis::BaseLoader, Symbol, nil]
  def entity_access_loader(entity)
    case entity
    when Hmis::Hud::Client
      Hmis::Hud::ClientAccessLoader.new(self)
    when Hmis::Hud::Project
      Hmis::Hud::ProjectAccessLoader.new(self)
    when Hmis::Hud::Organization
      Hmis::Hud::OrganizationAccessLoader.new(self)
    when Hmis::File
      :client
    else
      entity.class.reflect_on_association(:project) ? :project : nil
    end
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
