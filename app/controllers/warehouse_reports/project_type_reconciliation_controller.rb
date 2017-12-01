module WarehouseReports
  class ProjectTypeReconciliationController < ApplicationController
    before_action :require_can_view_all_reports!
    def index
      @projects = project_source.joins(:organization, :data_source).
        where(
          p_t[:act_as_project_type].not_eq(nil).
          and(p_t[:act_as_project_type].not_eq(p_t[:ProjectType]))
        ).
        order(ds_t[:short_name].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
    end

    def p_t
      project_source.arel_table
    end

    def o_t
      GrdaWarehouse::Hud::Organization.arel_table
    end

    def ds_t
      GrdaWarehouse::DataSource.arel_table
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end
  end
end
