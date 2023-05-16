###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl
  class EnrollmentArbiter
    include ArelHelper
    # access to client via:
    # 1. project assigned to user, access through enrollment -> project (project is, project, organization, data source, coc)
    # 2. ROI
    # 3. data source visible in window
    # 4. authoritative data source directly assigned to user
    # NOTE: All of these methods can be hinted with a set of source client ids.  Providing these, even a super set of
    # what you expect to return, can significantly improve performance

    # ROI - there are are two possible scenarios for ROIs:
    # 1. Clients become searchable when they have an ROI on file (set can_search_clients_with_roi)
    # 2. Additional client data becomes available when there's an ROI on file (set can_view_client_enrollments_with_roi)
    # these permissions need to be used in conjunction with an entity group indicating which project's enrollments should be included
    # In both cases the ROI must be site-wide or for specific CoCs

    # Access to client via:
    # 1. Enrollment at project where appropriate permission has been passed and the user has matching access control
    # 2. authoritative data source directly assigned to user (these have no enrollments/projects)

    # The following methods are public and called from other locations
    # clients_destination_visible_to
    # clients_source_visible_to
    # clients_source_searchable_to
    # enrollments_visible_to

    # Given source client visibility, which destination clients would be exposed to this user?
    def clients_destination_visible_to(user, source_client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user

      source_client_id_query = clients_source_visible_to(
        user,
        client_ids: source_client_ids,
      ).select(:id).to_sql
      unscoped_clients.joins(:warehouse_client_destination).
        where(wc_t[:source_id].in(Arel.sql(source_client_id_query)))
    end

    # Given a user, which source clients should be exposed in detail?
    # NOTE: this always uses can_view_clients OR can_view_client_enrollments_with_roi
    def clients_source_visible_to(user, client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user.can_access_some_version_of_clients?

      visible_client_scope(user, client_ids: client_ids)
    end

    # Given a user, which source clients should be exposed for search results?
    # NOTE: this always uses :can_search_own_clients OR can_search_clients_with_roi
    def clients_source_searchable_to(user, client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user

      searchable_client_scope(user, client_ids: client_ids)
    end

    # Access to client via:
    # 1. Enrollment at project where appropriate permission has been passed and the user has matching access control
    # 2. Client has an ROI that would expose data to this user via an access control
    # 3. authoritative data source directly assigned to user (these have no enrollments/projects)
    private def visible_client_scope(user, client_ids: nil)
      client_scope = unscoped_clients.source
      client_scope = client_scope.where(id: client_ids) if client_ids.present?

      # Active Record is doing some odd things with some of these, and sometimes
      # "none" is returning as "" which blows things up terribly.
      from_assigned_projects_query = viewable_enrollments_from_access_controls(user).joins(:client).select(c_t[:id]).to_sql
      from_rois_query = viewable_enrollments_from_rois(user).joins(:client).select(c_t[:id]).to_sql
      from_authoritative_ds = authoritative_viewable_ds_ids(user)

      where_clause = c_t[:id].in([]) # generates 1=0
      where_clause = where_clause.or(c_t[:id].in(Arel.sql(from_assigned_projects_query))) if from_assigned_projects_query.present?
      where_clause = where_clause.or(c_t[:id].in(Arel.sql(from_rois_query))) if from_rois_query.present?
      where_clause = where_clause.or(c_t[:data_source_id].in(from_authoritative_ds)) if from_authoritative_ds.any?

      client_scope.where(where_clause)
    end

    # Access to client in search results via:
    # 1. Enrollment at project where appropriate permission has been passed and the user has matching access control
    # 2. Client has an ROI that would expose data to this user via an access control
    # 3. authoritative data source directly assigned to user (these have no enrollments/projects)
    private def searchable_client_scope(user, client_ids: nil)
      client_scope = unscoped_clients.source
      client_scope = client_scope.where(id: client_ids) if client_ids.present?

      # Active Record is doing some odd things with some of these, and sometimes
      # "none" is returning as "" which blows things up terribly.
      from_assigned_projects_query = searchable_enrollments_from_access_controls(user).joins(:client).select(c_t[:id]).to_sql
      from_rois_query = searchable_enrollments_from_rois(user).joins(:client).select(c_t[:id]).to_sql
      from_authoritative_ds = authoritative_viewable_ds_ids(user)

      where_clause = c_t[:id].in([]) # generates 1=0
      where_clause = where_clause.or(c_t[:id].in(Arel.sql(from_assigned_projects_query))) if from_assigned_projects_query.present?
      where_clause = where_clause.or(c_t[:id].in(Arel.sql(from_rois_query))) if from_rois_query.present?
      where_clause = where_clause.or(c_t[:data_source_id].in(from_authoritative_ds)) if from_authoritative_ds.any?

      client_scope.where(where_clause)
    end

    # Given a user, access controls, and consent status of clients
    # Return scope of visible source clients
    # NOTE: this always operates on :can_view_clients
    private def viewable_enrollments_from_access_controls(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project).
        merge(
          ::GrdaWarehouse::Hud::Project.viewable_by(
            user,
            confidential_scope_limiter: :all,
            permission: :can_view_clients,
          ),
        )
    end

    private def viewable_enrollments_from_rois(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project, :client).
        merge(unscoped_clients.active_confirmed_consent_in_cocs(user.coc_codes)).
        merge(
          ::GrdaWarehouse::Hud::Project.viewable_by(
            user,
            confidential_scope_limiter: :all,
            permission: :can_view_client_enrollments_with_roi,
            # FIXME: need a migration to generate appropriate AccessControl
            # see DataSource obeys_consent, maybe with UserRole where can_view_clients
          ),
        )
    end

    # Analogous to visible_client_scope, execpt returns any enrollments where the
    # the user has access directly, or because of an ROI instead of clients
    # NOTE: authoritative clients won't have enrollments, so they are not included
    def enrollments_visible_to(user, client_ids: nil)
      scope = ::GrdaWarehouse::Hud::Enrollment.joins(:client)
      scope = scope.merge(::GrdaWarehouse::Hud::Client.where(id: client_ids)) if client_ids

      # Active Record is doing some odd things with some of these, and sometimes
      # "none" is returning as "" which blows things up terribly.
      from_assigned_projects_query = viewable_enrollments_from_access_controls(user).select(e_t[:id]).to_sql
      from_rois_query = viewable_enrollments_from_rois(user).select(e_t[:id]).to_sql

      where_clause = e_t[:id].in([]) # generates 1=0
      where_clause = where_clause.or(e_t[:id].in(Arel.sql(from_assigned_projects_query))) if from_assigned_projects_query.present?
      where_clause = where_clause.or(e_t[:id].in(Arel.sql(from_rois_query))) if from_rois_query.present?

      scope.where(where_clause)
    end

    # Given a user, access controls, and consent status of clients
    # Return scope of searchable source clients
    # NOTE: this always operates on :can_search_own_clients
    private def searchable_enrollments_from_access_controls(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project).
        merge(
          ::GrdaWarehouse::Hud::Project.viewable_by(
            user,
            confidential_scope_limiter: :all,
            permission: :can_search_own_clients,
          ),
        )
    end

    private def searchable_enrollments_from_rois(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project, :client).
        merge(unscoped_clients.active_confirmed_consent_in_cocs(user.coc_codes)).
        merge(
          ::GrdaWarehouse::Hud::Project.viewable_by(
            user,
            confidential_scope_limiter: :all,
            permission: :can_search_clients_with_roi,
            # FIXME: need a migration to generate appropriate AccessControl
            # see DataSource obeys_consent, maybe with UserRole where can_search_window
          ),
        )
    end

    # NOTE: because we call EnrollmentArbiter within a scope on client, the
    # default scope is mutated and must be removed
    def unscoped_clients
      ::GrdaWarehouse::Hud::Client.unscoped.paranoia_scope
    end

    private def authoritative_viewable_ds_ids(user)
      @authoritative_viewable_ds_ids ||= ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
    end

    # private def potentially_viewable_data_source_ids(user)
    #   @potentially_viewable_data_source_ids ||= ::GrdaWarehouse::DataSource.source.obeys_consent.pluck(:id) +
    #     ::GrdaWarehouse::DataSource.viewable_by(user).pluck(:id)
    # end
  end
end
