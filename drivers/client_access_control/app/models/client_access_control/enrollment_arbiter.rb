###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
    def clients_destination_visible_to(user)
      return ::GrdaWarehouse::Hud::Client.none unless user

      unscoped_clients.joins(:warehouse_client_destination).
        where(warehouse_clients: { source_id: clients_source_visible_to(user).select(:id) })
    end

    def clients_source_visible_to(user)
      return ::GrdaWarehouse::Hud::Client.none unless user.can_access_some_version_of_clients?

      data_source_ids = ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
      data_source_ids += ::GrdaWarehouse::DataSource.visible_in_window.pluck(:id) unless ::GrdaWarehouse::Config.get(:window_access_requires_release)
      visible_client_scope(user, data_source_ids)
    end

    def clients_source_searchable_to(user)
      return ::GrdaWarehouse::Hud::Client.none unless user

      data_source_ids = ::GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
      data_source_ids += ::GrdaWarehouse::DataSource.visible_in_window.pluck(:id)
      visible_client_scope(user, data_source_ids)
    end

    private def visible_client_scope(user, data_source_ids)
      client_scope = unscoped_clients.source
      client_scope.where(
        c_t[:id].in(Arel.sql(client_scope.joins(:enrollments).merge(enrollments_visible_to(user)).select(:id).to_sql)). # 1, 2
        or(c_t[:id].in(Arel.sql(client_scope.joins(:data_source).where(ds_t[:id].in(data_source_ids)).select(:id).to_sql))), # 3, 4
      )
    end

    def enrollments_visible_to(user)
      project_ids = ::GrdaWarehouse::Hud::Project.visible_to(user).pluck(:id).uniq
      coc_codes = user.coc_codes
      ::GrdaWarehouse::Hud::Enrollment.where(
        e_t[:id].in(Arel.sql(::GrdaWarehouse::Hud::Enrollment.joins(:project).where(p_t[:id].in(project_ids)).select(:id).to_sql)). # 1
        or(e_t[:id].in(Arel.sql(unscoped_clients.active_confirmed_consent_in_cocs(coc_codes).joins(:source_enrollments).select(e_t[:id]).to_sql))), # 2
      )
    end

    # NOTE: because we call EnrollmentArbiter within a scope on client, the
    # default scope is mutated and must be removed
    def unscoped_clients
      ::GrdaWarehouse::Hud::Client.unscoped.paranoia_scope
    end
  end
end
