###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::ProjectPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_edit_projects, :can_edit?],
    [:can_delete_projects, :can_delete?],
    [:can_view_projects, :can_view?],
    [:can_view_imports],
    [:can_view_clients],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      permission_granted_by_role?(permission)
    end
    memoize method_name
  end

  # delegate to the project's data source
  memoize def can_see_raw_hmis_data?
    user.policy_for(project.data_source, type: :data_source).can_see_raw_hmis_data?
  end

  # can the user see the project locations (on a map)
  memoize def can_view_project_locations?
    return false unless RailsDrivers.loaded.include?(:client_location_history)

    permission_granted_by_role?(:can_view_project_locations)
  end

  # for confidential projects, is there permission to view the name
  def can_view_name?
    return false unless permission_granted_by_role?(:can_view_projects)

    if project.confidential?
      permission_granted_by_role?(:can_edit_projects) || permission_granted_by_role?(:can_view_confidential_project_names)
    else
      true
    end
  end

  protected

  memoize def project
    resource_from_arg(resource, GrdaWarehouse::Hud::Project)
  end

  memoize def project_id
    id_from_arg(resource, GrdaWarehouse::Hud::Project)
  end

  # query the roles this the user has on the project; check if any of those roles grant the requested permission
  def permission_granted_by_role?(permission)
    # early return unless the user has this permission on any role. For acl users, this is performance optimization
    return false unless user.public_send("#{permission}?")

    if user.using_acls?
      user.access_controls.joins(:role).
        where(collection_id: project_collection_ids).
        merge(Role.where(permission => true)).any?
    else
      # check if the user is in any of the access groups
      user.access_groups.where(id: project_access_group_ids).exists?
    end
  end

  memoize def project_collection_ids
    p_t = GrdaWarehouse::Hud::Project.arel_table

    # collections including the project, org, project groups, etc
    collection_ids = GrdaWarehouse::ProjectCollectionMember.where(project_id: project_id).pluck(:collection_id)

    # collections for the projects via coc_codes
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.
      joins(:project).
      where(p_t[:id].eq(project_id)).
      pluck(:coc_code)
    collection_ids += Collection.for_coc_codes(coc_codes).pluck(:id) if coc_codes.any?

    collection_ids += system_collection_ids(:data_sources)
    collection_ids.uniq.sort
  end

  memoize def project_access_group_ids
    p_t = GrdaWarehouse::Hud::Project.arel_table

    # access groups including the project, org, project groups, etc
    access_group_ids = GrdaWarehouse::ProjectAccessGroupMember.where(project_id: project_id).pluck(:access_group_id)

    # access groups for the projects via coc_codes
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.
      joins(:project).
      where(p_t[:id].eq(project_id)).
      pluck(:coc_code)
    access_group_ids += AccessGroup.for_coc_codes(coc_codes).pluck(:id) if coc_codes.any?

    access_group_ids += system_access_group_ids(:data_sources)
    access_group_ids.uniq.sort
  end
end
