###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl
  class EnrollmentArbiter
    # access to client via:
    # 1. project assigned to user, access through enrollment -> project (project is, project, organization, data source, coc)
    # 2. ROI
    # 3. data source visible in window
    # 4. authoritative data source directly assigned to user
    def clients_destination_visible_to(scope, user)
      return none unless user

      scope.joins(:source_client).
        merge(scope.source_visible_to(user))
    end

    def clients_source_visible_to(scope, user)
      return none unless user
      return none unless user.can_access_some_version_of_clients?

      data_source_ids = GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
      data_source_ids += GrdaWarehouse::DataSource.visible_in_window.pluck(:id)
      scope.where(
        arel_table[:id].in(Arel.sql(scope.joins(:enrollments).merge(GrdaWarehouse::Hud::Enrollment.visible_to(user)).select(:id).to_sql)). # 1, 2
        or(arel_table[:id].in(Arel.sql(scope.joins(:data_source).where(ds_t[:id].in(data_source_ids).select(:id).to_sql)))), # 3, 4
      )
    end

    def enrollments_visible_to(scope, user)
      project_ids = GrdaWarehouse::Hud::Project.visible_to(user).pluck(:id).uniq
      coc_codes = user.coc_codes
      scope.where(
        arel_table[:id].in(Arel.sql(scope.joins(:project).where(p_t[:id].in(project_ids)))). # 1
        or(arel_table[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(coc_codes).joins(:source_enrollments).select(arel_table[:id]).to_sql))), # 2
      )
    end
  end
end
