###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::ClientPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_view_client_name, :can_view_name?],
    [:can_view_client_photo, :can_view_photo?],
    [:can_view_full_dob],
    [:can_view_full_ssn],
    [:can_view_hiv_status],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      permission_granted_by_role?(permission)
    end
    memoize method_name
  end

  # can the user see the full client dash page and additional details?
  memoize def can_view?
    return true if permission_granted_by_role?(:can_view_clients)

    permission_granted_through_roi?(:can_view_client_enrollments_with_roi)
  end

  # Can the user see the client record in search results? This provides minimal info on the client (compare to
  # can_view? which let's the user see the full client page)
  memoize def can_search?
    [
      :can_search_own_clients,
      :can_search_all_clients,
    ].any? do |permission|
      permission_granted_by_role?(permission)
    end

    permission_granted_through_roi?(:can_search_clients_with_roi)
  end

  protected

  memoize def client_id
    id_from_arg(resource, GrdaWarehouse::Hud::Client)
  end

  memoize def client
    resource_from_arg(resource, GrdaWarehouse::Hud::Client)
  end

  memoize def roi_authorizations
    destination = client.destination_client
    return [] unless destination

    destination.roi_authorizations.order(:id).filter(&:active?)
  end

  def permission_granted_by_role?(permission)
    # early return unless the user has this permission on any role. For acl users, this is performance optimization
    return false unless user.public_send("#{permission}?")

    if user.using_acls?
      user.access_controls.joins(:role).
        where(collection_id: client_collection_ids).
        merge(Role.where(permission => true)).any?
    else
      # check if the user is in any of the access groups
      user.access_groups.where(id: client_access_group_ids).exists?
    end
  end

  # An ROI confers some level of visibility to the client under the following circumstances:
  # - the source client must be in a data source with `obeys_consent=true`
  # - the ROI has a valid status (not revoked). ROI fields are stored on the destination client record (for now)
  # - if the ROI is restricted to certain COCs then the user's COCs must match
  # - the user has a role granting permission on source client project as follows:
  #   - if the user has `can_search_client_with_roi`, we grant `can_search_own_clients` and `can_search_all_clients`
  #   - if the user has `can_view_client_enrollments_with_roi`, we grant `can_view_clients`
  # - ROI does not confer additional permissions. Additional permissions are identical to clients without an ROI, such as via direct assignment
  def permission_granted_through_roi?(permission)
    return false unless client.data_source.obey_consent?

    if roi_authorizations.present? && permission_granted_by_role?(permission)
      return true if roi_authorizations.any? { |a| a.matches_coc_codes?(user.coc_codes) }
    end
    false
  end

  # Collection IDs that contain this client (through an enrollment at a project, coc, or data source)
  memoize def client_collection_ids
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table

    # collections including the client's enrolled projects, orgs, project groups, etc
    collection_ids = GrdaWarehouse::ProjectCollectionMember.
      joins(project: :clients).
      where(c_t[:id].eq(client_id)).
      pluck(:collection_id)

    # collections for the client's enrolled projects via coc_codes
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.
      joins(project: :clients).
      where(c_t[:id].eq(client_id)).
      pluck(:coc_code)
    collection_ids += Collection.for_coc_codes(coc_codes).pluck(:id) if coc_codes.any?

    # collections for the client's authoritative data source. Needed for clients records that do not have enrollments
    collection_ids += GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:collection_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:collection_id])

    collection_ids += system_collection_ids(:data_sources)
    collection_ids.uniq.sort
  end

  # Access Group IDs that contain this client (through an enrollment at a project, coc, or data source)
  memoize def client_access_group_ids
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table

    # access_groups including the client's enrolled projects, orgs, project groups, etc
    access_group_ids = GrdaWarehouse::ProjectAccessGroupMember.
      joins(project: :clients).
      where(c_t[:id].eq(client_id)).
      pluck(:access_group_id)

    # access_groups for the client's enrolled projects via coc_codes
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.
      joins(project: :clients).
      where(c_t[:id].eq(client_id)).
      pluck(:coc_code)
    access_group_ids += AccessGroup.for_coc_codes(coc_codes).pluck(:id) if coc_codes.any?

    # access_groups for the client's authoritative data source. Needed for clients records that do not have enrollments
    access_group_ids += GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:access_group_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:access_group_id])

    access_group_ids += system_access_group_ids(:data_sources)
    access_group_ids.uniq.sort
  end
end
