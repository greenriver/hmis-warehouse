###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'memery'

# cross-policy memoized utils for Legacy user-role-based permissions
class GrdaWarehouse::AuthPolicies::UserLegacyContext
  include Memery
  attr_accessor :user

  EMPTY_SET = Set.new.freeze

  def initialize(user)
    @user = user
    raise ArgumentError, 'cannot be acl user' if @user.using_acls?

    @coc_codes_by_project = {}
    @access_group_ids_by_project = {}
  end

  memoize def project_role_permissions(project_id)
    access_group_ids = project_access_group_ids(project_id)
    permissions_for_access_group_ids(access_group_ids)
  end

  memoize def data_source_role_permissions(data_source_id)
    access_group_ids = data_source_access_group_ids(data_source_id)
    permissions_for_access_group_ids(access_group_ids)
  end

  memoize def direct_client_role_permissions(client_id)
    access_group_ids = direct_client_access_group_ids(client_id)
    permissions_for_access_group_ids(access_group_ids)
  end

  def preload_project_dependencies(project_ids)
    preload_coc_codes_by_project(project_ids)
    preload_access_group_ids_by_project(project_ids)
  end

  memoize def legacy_permissions
    user.legacy_roles.flat_map(&:granted_permissions).to_set.freeze
  end

  memoize def legacy_window_access_requires_release?
    ::GrdaWarehouse::Config.get(:window_access_requires_release)
  end

  memoize def legacy_window_data_source_ids
    ::GrdaWarehouse::DataSource.window_data_source_ids.to_set.freeze
  end

  protected

  def preload_coc_codes_by_project(project_ids)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    results = GrdaWarehouse::Hud::ProjectCoc.
      joins(:project).
      where(p_t[:id].in(project_ids)).
      pluck(p_t[:id], :coc_code).
      group_by(&:shift).
      transform_values(&:flatten)
    @coc_codes_by_project.merge!(results)
  end

  def coc_codes_for_project(project_id)
    preload_coc_codes_by_project([project_id]) unless @coc_codes_by_project.key?(project_id)
    @coc_codes_by_project[project_id] ||= []
  end

  def preload_access_group_ids_by_project(project_ids)
    results = GrdaWarehouse::ProjectAccessGroupMember.
      where(project_id: project_ids).
      pluck(:project_id, :access_group_id).
      group_by(&:shift).
      transform_values(&:flatten)
    @access_group_ids_by_project.merge!(results)
  end

  def access_group_ids_for_project(project_id)
    preload_access_group_ids_by_project([project_id]) unless @access_group_ids_by_project.key?(project_id)
    @access_group_ids_by_project[project_id] ||= []
  end

  memoize def system_access_group_ids(group_name)
    [AccessGroup.system_groups[group_name]&.id].compact
  end

  memoize def permissions_for_access_group_ids(access_group_ids)
    access_group_ids += system_access_group_ids(:data_sources)
    return EMPTY_SET if access_group_ids.blank?
    return EMPTY_SET unless user.access_groups.where(id: access_group_ids).exists?

    legacy_permissions
  end

  def data_source_access_group_ids(data_source_id)
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity_type: GrdaWarehouse::DataSource.sti_name).
      where(entity_id: data_source_id).
      where.not(access_group_id: nil).
      pluck(:access_group_id)
    ids.uniq.sort
  end

  # Returns the access group ids that include this project id
  def project_access_group_ids(project_id)
    access_group_ids = access_group_ids_for_project(project_id)
    coc_codes = coc_codes_for_project(project_id)

    # two queries are required because COC codes are on the app db
    access_group_ids += access_group_for_coc_codes(coc_codes) if coc_codes.any?

    access_group_ids.uniq.sort
  end

  memoize private def access_group_for_coc_codes(coc_codes)
    AccessGroup.for_coc_codes(coc_codes).pluck(:id)
  end

  # These are source clients, mostly for health-care and youth. See DataSource.authoritative_types.
  # It's an affordance for direct data entry into the warehouse before we had an HMIS, or non HMIS data.
  def direct_client_access_group_ids(client_id)
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table
    GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:access_group_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:access_group_id])
  end
end
