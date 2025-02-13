###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

# cross-policy memoized utils for ACL permissions
class GrdaWarehouse::AuthPolicies::UserAclContext
  include Memery
  attr_accessor :user
  EMPTY_SET = Set.new.freeze

  def initialize(user)
    @user = user
    raise ArgumentError, 'must be acl user' unless @user.using_acls?
  end

  memoize def project_role_permissions(project_or_project_id)
    collection_ids = project_collection_ids(project_or_project_id)
    permissions_for_collection_ids(collection_ids)
  end

  memoize def data_source_role_permissions(data_source_id)
    collection_ids = data_source_collection_ids(data_source_id)
    permissions_for_collection_ids(collection_ids)
  end

  memoize def direct_client_role_permissions(client_id)
    collection_ids = direct_client_collection_ids(client_id)
    permissions_for_collection_ids(collection_ids)
  end

  # Duck-typed for legacy role-based permissions
  def legacy_permissions
    EMPTY_SET
  end

  protected

  memoize def system_collection_ids(group_name)
    [Collection.system_collection(group_name)&.id].compact
  end

  memoize def permissions_for_collection_ids(collection_ids)
    collection_ids += system_collection_ids(:data_sources)
    return EMPTY_SET if collection_ids.blank?

    Role.joins(:access_controls).
      merge(user.access_controls.where(collection_id: collection_ids)).
      flat_map(&:granted_permissions).to_set.freeze
  end

  memoize def data_source_collection_ids(data_source_id)
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity_type: GrdaWarehouse::DataSource.sti_name).
      where(entity_id: data_source_id).
      where.not(collection_id: nil).
      pluck(:collection_id)
    ids.uniq.sort
  end

  # Accepts a project instance or project id (primary key).  If passed a project
  # you probably want to preload(:project_collection_members, :project_cocs) to avoid
  # N+1s
  # Returns the collection ids that include this project
  def project_collection_ids(project_or_project_id)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    collection_ids = []
    coc_codes = []
    if project_or_project_id.is_a?(GrdaWarehouse::Hud::Project)
      collection_ids = project_or_project_id.project_collection_members.map(&:collection_id)
      coc_codes = project_or_project_id.project_cocs.map(&:coc_code)
    else
      # collections including the project, org, project groups, etc
      collection_ids = GrdaWarehouse::ProjectCollectionMember.
        where(project_id: project_or_project_id).
        pluck(:collection_id)

      # collections for the projects via coc_codes
      coc_codes = GrdaWarehouse::Hud::ProjectCoc.
        joins(:project).
        where(p_t[:id].eq(project_or_project_id)).
        pluck(:coc_code)
    end
    # two queries are required because COC codes are on the app db
    collection_ids += collection_for_coc_codes(coc_codes) if coc_codes.any?

    collection_ids.uniq.sort
  end

  memoize private def collection_for_coc_codes(coc_codes)
    Collection.for_coc_codes(coc_codes).pluck(:id)
  end

  # These are source clients, mostly for health-care and youth. See DataSource.authoritative_types.
  # It's an affordance for direct data entry into the warehouse before we had an HMIS, or non HMIS data.
  def direct_client_collection_ids(client_id)
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table
    GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:collection_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:collection_id])
  end
end
