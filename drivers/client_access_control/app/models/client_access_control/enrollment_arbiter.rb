###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl
  class EnrollmentArbiter
    def clients_destination_visible_to(scope, user)
      return none unless user

      scope.joins(:source_client).
        merge(scope.source_visible_to(user))
    end

    def clients_source_visible_to(scope, user)
      return none unless user
      return none unless user.can_view_full_client_dashboard? || user.can_view_limited_client_dashboard?

      data_source_ids = GrdaWarehouse::DataSource.authoritative.directly_viewable_by(user).pluck(:id)
      scope.where(
        arel_table[:id].in(Arel.sql(scope.joins(:enrollments).merge(GrdaWarehouse::Hud::Enrollment.visible_to(user)).select(:id).to_sql)).
        or(arel_table[:id].in(Arel.sql(scope.joins(:data_source).where(ds_t[:id].in(data_source_ids).select(:id).to_sql)))),
      )
    end

    def enrollments_visible_to(scope, user)
      project_ids = GrdaWarehouse::Hud::Project.visible_to(user).pluck(:id).uniq
      coc_codes = user.coc_codes
      scope.where(
        arel_table[:id].in(Arel.sql(scope.joins(:project).where(p_t[:id].in(project_ids)))).
        or(arel_table[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(coc_codes).joins(:source_enrollments).select(arel_table[:id]).to_sql))),
      )
    end
  end
end
