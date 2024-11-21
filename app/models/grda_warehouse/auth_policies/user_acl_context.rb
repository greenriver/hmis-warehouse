###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  memoize def project_role_permissions(project_id)
    collection_ids = project_collection_ids(project_id)
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

  memoize def client_window_data_source_permissions(...)
    EMPTY_SET
  end

  protected

  memoize def system_collection_ids(group_name)
    [Collection.system_collection(group_name)&.id].compact
  end

  def permissions_for_collection_ids(collection_ids)
    collection_ids += system_collection_ids(:data_sources)
    return EMPTY_SET if collection_ids.blank?

    Role.joins(:access_controls).
      merge(user.access_controls.where(collection_id: collection_ids)).
      flat_map(&:granted_permissions).to_set.freeze
  end

  def data_source_collection_ids(data_source_id)
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity_type: GrdaWarehouse::DataSource.sti_name).
      where(entity_id: data_source_id).
      where.not(collection_id: nil).
      pluck(:collection_id)
    ids.uniq.sort
  end

  def project_collection_ids(project_id)
    p_t = GrdaWarehouse::Hud::Project.arel_table

    # collections including the project, org, project groups, etc
    collection_ids = GrdaWarehouse::ProjectCollectionMember.
      where(project_id: project_id).
      pluck(:collection_id)

    # collections for the projects via coc_codes
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.
      joins(:project).
      where(p_t[:id].eq(project_id)).
      pluck(:coc_code)
    # two queries are required because COC codes are on the app db
    collection_ids += Collection.for_coc_codes(coc_codes).pluck(:id) if coc_codes.any?

    collection_ids.uniq.sort
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
