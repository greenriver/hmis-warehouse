###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::DataSourcePolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_edit_data_sources, :can_edit?],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      permission_granted_by_role?(permission)
    end
    memoize method_name
  end

  memoize def can_see_raw_hmis_data?
    permission_granted_by_role?(:can_edit_data_sources) && permission_granted_by_role?(:can_upload_hud_zips)
  end

  protected

  def permission_granted_by_role?(permission)
    # early return unless the user has this permission on any role. For acl users, this is performance optimization
    return false unless user.public_send("#{permission}?")

    if user.using_acls?
      user.access_controls.joins(:role).
        where(collection_id: data_source_collection_ids).
        merge(Role.where(permission => true)).any?
    else
      # check if the user is in any of the access groups
      user.access_groups.where(id: data_source_access_group_ids).exists?
    end
  end

  memoize def data_source
    resource_from_arg(resource, GrdaWarehouse::DataSource)
  end

  memoize def data_source_id
    id_from_arg(resource, GrdaWarehouse::DataSource)
  end

  def permission_granted_by_role?(permission)
    if user.using_acls?
      user.access_controls.joins(:role).
        where(collection_id: data_source_collection_ids).
        merge(Role.where(permission => true)).any?
    else
      # check if the user has permission on any role
      return false unless user.public_send("#{permission}?")

      # check if the user is in any of the access groups
      user.access_groups.where(id: data_source_access_group_ids).exists?
    end
  end

  memoize def data_source_collection_ids
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity: data_source).
      where.not(collection_id: nil).
      pluck(:collection_id)
    ids += system_collection_ids(:data_sources)
    ids.uniq.sort
  end

  memoize def data_source_access_group_ids
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity: data_source).
      where.not(access_group_id: nil).
      pluck(:access_group_id)
    ids += system_access_group_ids(:data_sources)
    ids.uniq.sort
  end
end
