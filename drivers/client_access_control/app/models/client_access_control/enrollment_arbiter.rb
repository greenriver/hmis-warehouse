###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

      # TODO: START_ACL cleanup after ACL migration is complete
      if user.using_acls?
        source_client_id_query = clients_source_visible_to(
          user,
          client_ids: source_client_ids,
        ).select(:id).to_sql
        return ::GrdaWarehouse::Hud::Client.none unless source_client_id_query.present?

        unscoped_clients.joins(:warehouse_client_destination).
          where(wc_t[:source_id].in(Arel.sql(source_client_id_query)))
      else
        unscoped_clients.joins(:warehouse_client_destination).
          where(warehouse_clients: { source_id: clients_source_visible_to(user, client_ids: source_client_ids).select(:id) })
      end
    end

    # Given a user, which source clients should be exposed in detail?
    # NOTE: this always uses can_view_clients OR can_view_client_enrollments_with_roi
    def clients_source_visible_to(user, client_ids: nil)
      # TODO: START_ACL cleanup after ACL migration is complete
      if user.using_acls?
        visible_client_scope(user, client_ids: client_ids)
      else
        return ::GrdaWarehouse::Hud::Client.none unless user.can_access_some_version_of_clients?

        data_source_ids = legacy_authoritative_viewable_ds_ids(user)
        data_source_ids += window_data_source_ids unless ::GrdaWarehouse::Config.get(:window_access_requires_release)
        legacy_visible_client_scope(user, data_source_ids, client_ids: client_ids)
      end
    end

    # Given a user, which source clients should be exposed for search results?
    # NOTE: this always uses :can_search_own_clients OR can_search_clients_with_roi
    def clients_source_searchable_to(user, client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user

      # TODO: START_ACL cleanup after ACL migration is complete
      if user.using_acls?
        searchable_client_scope(user, client_ids: client_ids)
      else
        data_source_ids = legacy_authoritative_viewable_ds_ids(user)
        data_source_ids += window_data_source_ids # always include window data sources in search
        legacy_visible_client_scope(user, data_source_ids, client_ids: client_ids)
      end
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
      from_authoritative_ds = authoritative_viewable_ds_ids(user, permission: :can_view_clients)

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
      from_authoritative_ds = authoritative_viewable_ds_ids(user, permission: :can_search_own_clients)

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
      # Consent is always stored on the destination record
      consented_destination_clients = unscoped_clients.active_confirmed_consent_in_cocs(user.coc_codes).select(c_t[:id]).to_sql
      consent_query = ::GrdaWarehouse::WarehouseClient.
        where(wc_t[:destination_id].in(Arel.sql(consented_destination_clients))).
        select(wc_t[:source_id]).to_sql
      return ::GrdaWarehouse::Hud::Enrollment.none unless consent_query

      ::GrdaWarehouse::Hud::Enrollment.joins(:project, :client).
        where(c_t[:id].in(Arel.sql(consent_query))).
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

    # TODO: START_ACL remove after ACL migration is complete
    private def legacy_visible_client_scope(user, data_source_ids, client_ids: nil)
      client_scope = unscoped_clients.source
      client_scope = client_scope.where(id: client_ids) if client_ids.present?
      coc_codes = user.coc_codes

      # NOTE: you need to merge in Enrollment to get the where DateDeleted is null
      # also, it is more performant to sub-query enrollments for unknown reasons.
      where_clause = c_t[:id].in(
        Arel.sql(
          client_scope.joins(:enrollments).merge(::GrdaWarehouse::Hud::Enrollment.paranoia_scope).
          where(e_t[:id].in(Arel.sql(enrollment_sub_query(user).select(:id).to_sql))).
          select(c_t[:id]).to_sql,
        ),
      ) # 1
      # The can_search_own_clients permission limits search results regardles of ROI status
      unless user.can_search_own_clients?
        where_clause = where_clause.or(
          c_t[:id].in(
            Arel.sql(
              consent_sub_query(coc_codes, user).
              joins(:warehouse_client_destination).
              select(wc_t[:source_id]).to_sql,
            ),
          ),
        ) # 2
      end
      where_clause = where_clause.or(
        c_t[:id].in(
          Arel.sql(
            client_scope.
            joins(:data_source).
            where(ds_t[:id].in(data_source_ids)).
            select(:id).to_sql,
          ),
        ),
      ) # 3, 4
      client_scope.where(where_clause)
    end
    # END_ACL

    # Analogous to visible_client_scope, except returns any enrollments where the
    # the user has access directly, or because of an ROI instead of clients
    # NOTE: authoritative clients won't have enrollments, so they are not included
    def enrollments_visible_to(user, client_ids: nil)
      # TODO: START_ACL cleanup after ACL migration is complete
      if user.using_acls?
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
      else
        coc_codes = user.coc_codes
        enrollments = enrollment_sub_query(user)
        enrollments = enrollments.joins(:client).merge(unscoped_clients.where(id: client_ids)) if client_ids.present?
        ::GrdaWarehouse::Hud::Enrollment.where(
          e_t[:id].in(Arel.sql(enrollments.select(:id).to_sql)). # 1
          or(e_t[:id].in(Arel.sql(consent_sub_query(coc_codes, user).joins(:source_enrollments).select(e_t[:id]).to_sql))), # 2
        )
      end
      # END_ACL
    end

    private def searchable_enrollments_from_rois(user)
      # Consent is always stored on the destination record
      consented_destination_clients = unscoped_clients.active_confirmed_consent_in_cocs(user.coc_codes).select(c_t[:id]).to_sql
      consent_query = ::GrdaWarehouse::WarehouseClient.
        where(wc_t[:destination_id].in(Arel.sql(consented_destination_clients))).
        select(wc_t[:source_id]).to_sql
      return ::GrdaWarehouse::Hud::Enrollment.none unless consent_query

      ::GrdaWarehouse::Hud::Enrollment.joins(:project, :client).
        where(c_t[:id].in(Arel.sql(consent_query))).
        merge(
          ::GrdaWarehouse::Hud::Project.viewable_by(
            user,
            confidential_scope_limiter: :all,
            permission: :can_search_clients_with_roi,
          ),
        )
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

    # TODO: START_ACL remove after ACL migration is complete
    private def enrollment_sub_query(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project).where(p_t[:id].in(project_ids(user)))
    end

    private def consent_sub_query(coc_codes, user)
      unscoped_clients.active_confirmed_consent_in_cocs(coc_codes).
        where(wc_t[:data_source_id].in(potentially_viewable_data_source_ids(user)))
    end
    # END_ACL

    # NOTE: because we call EnrollmentArbiter within a scope on client, the
    # default scope is mutated and must be removed
    def unscoped_clients
      ::GrdaWarehouse::Hud::Client.unscoped.paranoia_scope
    end

    # TODO: START_ACL remove after ACL migration is complete
    private def legacy_authoritative_viewable_ds_ids(user)
      @legacy_authoritative_viewable_ds_ids ||= ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
    end

    private def window_data_source_ids
      @window_data_source_ids ||= ::GrdaWarehouse::DataSource.window_data_source_ids
    end

    private def potentially_viewable_data_source_ids(user)
      @potentially_viewable_data_source_ids ||= ::GrdaWarehouse::DataSource.source.obeys_consent.pluck(:id) +
        ::GrdaWarehouse::DataSource.viewable_by(user).pluck(:id)
    end

    private def project_ids(user)
      @project_ids ||= begin
        ids = ::GrdaWarehouse::Hud::Project.visible_to(user, confidential_scope_limiter: :all).pluck(:id).uniq
        if ::GrdaWarehouse::Config.get(:window_access_requires_release)
          ids
        else
          ids + ::GrdaWarehouse::Hud::Project.where(data_source_id: window_data_source_ids).pluck(:id)
        end
      end
    end
    # END_ACL

    private def authoritative_viewable_ds_ids(user, permission: :can_view_clients)
      @authoritative_viewable_ds_ids ||= ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user, permission: permission).pluck(:id)
    end
  end
end
