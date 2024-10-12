###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

class GrdaWarehouse::AuthPolicies::PolicyProvider
  include Memery
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # current_user.polices.for_client(client).can_...
  def for_client(client_or_id)
    client_id = id_from_arg(client_or_id, GrdaWarehouse::Hud::Client)
    if user.using_acls?
      for_client_using_acls(client_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      for_client_using_roles(client_id)
      # END_ACL
    end
  end

  def for_patient(patient)
    for_client(patient.client_id)
  end

  def for_project(project_or_id)
    project_id = id_from_arg(project_or_id, GrdaWarehouse::Hud::Project)
    if user.using_acls?
      for_project_using_acls(project_id)
    else
      # TODO: START_ACL remove after ACL migration is complete
      for_project_using_roles(project_id)
      # END_ACL
    end
  end

  protected

  # Policy determined by the intersection of the user's collections and project's collections
  memoize def for_project_using_acls(project_id)
    collection_ids = all_collection_ids_for_project(project_id: project_id)
    GrdaWarehouse::AuthPolicies::CollectionPolicy.new(user: user, collection_ids: collection_ids)
  end

  # Policy determined by the intersection of the user's collections and client's collections
  memoize def for_client_using_acls(client_id)
    collection_ids = all_collection_ids_for_client(client_id: client_id)
    GrdaWarehouse::AuthPolicies::CollectionPolicy.new(user: user, collection_ids: collection_ids)
  end

  memoize def system_collection_ids(group_name)
    [Collection.system_collection(group_name)&.id].compact
  end

  def id_from_arg(arg, klass)
    case arg
    when klass
      arg.id
    when Integer, String
      arg.to_i
    else
      raise "invalid argument #{arg.inspect}"
    end
  end

  def all_collection_ids_for_project(project_id:)
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

  def all_collection_ids_for_client(client_id:)
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

  # TODO: START_ACL remove after ACL migration is complete
  memoize def for_client_using_roles(client_id)
    access_group_ids = all_access_group_ids_for_client(client_id: client_id)
    GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy.new(user: user, access_group_ids: access_group_ids)
  end

  memoize def for_project_using_roles(project_id)
    access_group_ids = all_access_group_ids_for_project(project_id: project_id)
    GrdaWarehouse::AuthPolicies::LegacyUserRolePolicy.new(user: user, access_group_ids: access_group_ids)
  end

  def all_access_group_ids_for_project(project_id:)
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

  def all_access_group_ids_for_client(client_id:)
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

  memoize def system_access_group_ids(group_name)
    [AccessGroup.system_groups[group_name]&.id].compact
  end
  # END_ACL
end
