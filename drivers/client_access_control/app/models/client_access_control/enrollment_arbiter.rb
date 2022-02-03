###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    def clients_destination_visible_to(user, source_client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user

      unscoped_clients.joins(:warehouse_client_destination).
        where(warehouse_clients: { source_id: clients_source_visible_to(user, client_ids: source_client_ids).select(:id) })
    end

    def clients_source_visible_to(user, client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user.can_access_some_version_of_clients?

      data_source_ids = authoritative_viewable_ds_ids(user)
      data_source_ids += window_data_source_ids unless ::GrdaWarehouse::Config.get(:window_access_requires_release)
      visible_client_scope(user, data_source_ids, client_ids: client_ids)
    end

    def clients_source_searchable_to(user, client_ids: nil)
      return ::GrdaWarehouse::Hud::Client.none unless user

      data_source_ids = authoritative_viewable_ds_ids(user)
      data_source_ids += window_data_source_ids # always include window data sources in search
      visible_client_scope(user, data_source_ids, client_ids: client_ids)
    end

    private def visible_client_scope(user, data_source_ids, client_ids: nil)
      client_scope = unscoped_clients.source
      client_scope = client_scope.where(id: client_ids) if client_ids.present?
      coc_codes = user.coc_codes
      client_scope.where(
        # NOTE: you need to merge in Enrollment to get the where DateDeleted is null
        # also, it is more performant to sub-query enrollments for unknown reasons
        c_t[:id].in(
          Arel.sql(
            client_scope.joins(:enrollments).merge(::GrdaWarehouse::Hud::Enrollment.paranoia_scope).
            where(e_t[:id].in(Arel.sql(enrollment_sub_query(user).select(:id).to_sql))).
            select(c_t[:id]).to_sql,
          ),
        ). # 1
        or(c_t[:id].in(Arel.sql(consent_sub_query(coc_codes).joins(:warehouse_client_destination).select(wc_t[:source_id]).to_sql))). # 2
        or(c_t[:id].in(Arel.sql(client_scope.joins(:data_source).where(ds_t[:id].in(data_source_ids)).select(:id).to_sql))), # 3, 4
      )
    end

    def enrollments_visible_to(user, client_ids: nil)
      coc_codes = user.coc_codes
      enrollments = enrollment_sub_query(user)
      enrollments = enrollments.joins(:client).merge(unscoped_clients.where(id: client_ids)) if client_ids.present?
      ::GrdaWarehouse::Hud::Enrollment.where(
        e_t[:id].in(Arel.sql(enrollments.select(:id).to_sql)). # 1
        or(e_t[:id].in(Arel.sql(consent_sub_query(coc_codes).joins(:source_enrollments).select(e_t[:id]).to_sql))), # 2
      )
    end

    private def enrollment_sub_query(user)
      ::GrdaWarehouse::Hud::Enrollment.joins(:project).where(p_t[:id].in(project_ids(user)))
    end

    private def consent_sub_query(coc_codes)
      unscoped_clients.active_confirmed_consent_in_cocs(coc_codes)
    end

    # NOTE: because we call EnrollmentArbiter within a scope on client, the
    # default scope is mutated and must be removed
    def unscoped_clients
      ::GrdaWarehouse::Hud::Client.unscoped.paranoia_scope
    end

    private def authoritative_viewable_ds_ids(user)
      @authoritative_viewable_ds_ids ||= ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
    end

    private def window_data_source_ids
      @window_data_source_ids ||= ::GrdaWarehouse::DataSource.window_data_source_ids
    end

    private def project_ids(user)
      @project_ids ||= begin
        ids = ::GrdaWarehouse::Hud::Project.visible_to(user).pluck(:id).uniq
        if ::GrdaWarehouse::Config.get(:window_access_requires_release)
          ids
        else
          ids + ::GrdaWarehouse::Hud::Project.where(data_source_id: window_data_source_ids).pluck(:id)
        end
      end
    end
  end
end
