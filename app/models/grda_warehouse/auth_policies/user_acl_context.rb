###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-auth-policies.md

# cross-policy memoized utils for ACL permissions
class GrdaWarehouse::AuthPolicies::UserAclContext < GrdaWarehouse::AuthPolicies::UserBaseContext
  def initialize(user)
    super(user)
    raise ArgumentError, 'must be acl user' unless @user.using_acls?

    @coc_codes_by_project = {}
    @collection_ids_by_project = {}
    @collection_ids_by_client = {}
    @enrolled_project_ids_by_client = {}
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

  # Returns the project ids this client is enrolled in. Called by
  # SourceClientPolicy#add_project_based_permissions (public, since it's used across
  # policy classes, same as #project_role_permissions/#direct_client_role_permissions).
  def enrolled_project_ids_for_client(client_id)
    preload_enrolled_project_ids_by_client([client_id]) unless @enrolled_project_ids_by_client.key?(client_id)
    @enrolled_project_ids_by_client[client_id] ||= []
  end

  def preload_project_dependencies(project_ids)
    preload_coc_codes_by_project(project_ids)
    preload_collection_ids_by_project(project_ids)
  end

  # Warms the caches consulted by #direct_client_role_permissions and
  # SourceClientPolicy#add_project_based_permissions (via #enrolled_project_ids_for_client)
  # for a whole batch of client ids in a small constant number of queries, instead of
  # one query per client. Also warms project_role_permissions for every project the
  # batch is enrolled in, so per-client permission checks don't re-trigger per-project N+1.
  def preload_client_dependencies(client_ids)
    preload_collection_ids_by_client(client_ids)
    preload_enrolled_project_ids_by_client(client_ids)
    project_ids = client_ids.flat_map { |id| @enrolled_project_ids_by_client[id] || [] }.uniq
    preload_project_dependencies(project_ids) if project_ids.any?
  end

  # Duck-typed for legacy role-based permissions
  def legacy_permissions
    EMPTY_SET
  end

  protected

  def preload_coc_codes_by_project(project_ids)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    results = GrdaWarehouse::Hud::ProjectCoc.
      joins(:project).
      where(p_t[:id].in(project_ids)).
      pluck(p_t[:id], :coc_code).
      group_by(&:shift).
      transform_values { |v| v.flatten.compact_blank }
    @coc_codes_by_project.merge!(results)
  end

  def coc_codes_for_project(project_id)
    preload_coc_codes_by_project([project_id]) unless @coc_codes_by_project.key?(project_id)
    @coc_codes_by_project[project_id] ||= []
  end

  def preload_collection_ids_by_project(project_ids)
    results = GrdaWarehouse::ProjectCollectionMember.
      where(project_id: project_ids).
      pluck(:project_id, :collection_id).
      group_by(&:shift).
      transform_values do |values|
        clean_values = values.flatten.compact_blank
        # Filter out deleted collection. ProjectCollectionMember can't do this due to database boundaries
        (active_collection_ids & clean_values).to_a
      end

    @collection_ids_by_project.merge!(results)
  end

  def collection_ids_for_project(project_id)
    preload_collection_ids_by_project([project_id]) unless @collection_ids_by_project.key?(project_id)
    @collection_ids_by_project[project_id] ||= []
  end

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

  def data_source_collection_ids(data_source_id)
    ids = GrdaWarehouse::GroupViewableEntity.
      where(entity_type: GrdaWarehouse::DataSource.sti_name).
      where(entity_id: data_source_id).
      where.not(collection_id: nil).
      pluck(:collection_id)
    (active_collection_ids & ids).to_a.sort
  end

  # Returns the collection ids that include this project id
  def project_collection_ids(project_id)
    collection_ids = collection_ids_for_project(project_id)
    coc_codes = coc_codes_for_project(project_id)

    # two queries are required because COC codes are on the app db
    collection_ids += collection_for_coc_codes(coc_codes) if coc_codes.any?

    collection_ids.uniq.sort
  end

  memoize private def collection_for_coc_codes(coc_codes)
    Collection.for_coc_codes(coc_codes).pluck(:id)
  end

  # These are source clients, mostly for health-care and youth. See DataSource.authoritative_types.
  # It's an affordance for direct data entry into the warehouse before we had an HMIS, or non HMIS data.
  def preload_collection_ids_by_client(client_ids)
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table
    results = GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:collection_id].not_eq(nil)).
      where(c_t[:id].in(client_ids)).
      pluck(c_t[:id], gve_t[:collection_id]).
      group_by(&:shift).
      transform_values { |v| (active_collection_ids & v.flatten.compact_blank).to_a.sort }
    @collection_ids_by_client.merge!(results)
  end

  def direct_client_collection_ids(client_id)
    preload_collection_ids_by_client([client_id]) unless @collection_ids_by_client.key?(client_id)
    @collection_ids_by_client[client_id] ||= []
  end

  # Backing query for #enrolled_project_ids_for_client,
  # used to preload a batch of clients via #preload_client_dependencies.
  def preload_enrolled_project_ids_by_client(client_ids)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    c_t = GrdaWarehouse::Hud::Client.arel_table
    results = GrdaWarehouse::Hud::Project.joins(:clients).
      where(c_t[:id].in(client_ids)).
      distinct.
      pluck(c_t[:id], p_t[:id]).
      group_by(&:shift).
      transform_values(&:flatten)
    @enrolled_project_ids_by_client.merge!(results)
  end

  memoize def active_collection_ids
    Set.new(Collection.pluck(:id))
  end
end
