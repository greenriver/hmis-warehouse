###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'memery'

# cross-policy memoized utils for ACL permissions
class GrdaWarehouse::AuthPolicies::UserAclContext
  include Memery
  attr_accessor :user
  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'must be acl user' unless user.is_a?(User) && user.using_acls?

    @user = user
    @coc_codes_by_project = {}
    @collection_ids_by_project = {}
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

  def preload_project_dependencies(project_ids)
    preload_coc_codes_by_project(project_ids)
    preload_collection_ids_by_project(project_ids)
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
  def direct_client_collection_ids(client_id)
    c_t = GrdaWarehouse::Hud::Client.arel_table
    gve_t = GrdaWarehouse::GroupViewableEntity.arel_table
    ids = GrdaWarehouse::DataSource.authoritative.not_hmis.
      joins(:group_viewable_entities, :clients).
      where(gve_t[:collection_id].not_eq(nil)).
      where(c_t[:id].eq(client_id)).
      pluck(gve_t[:collection_id])
    (active_collection_ids & ids).to_a.sort
  end

  memoize def active_collection_ids
    Set.new(Collection.pluck(:id))
  end
end
