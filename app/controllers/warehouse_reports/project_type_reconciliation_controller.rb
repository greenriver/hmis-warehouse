module WarehouseReports
  class ProjectTypeReconciliationController < WarehouseReportsController
    include ArelHelper
    include WarehouseReportAuthorization
    def index
      @projects = project_source.joins(:organization, :data_source).
        where(
          p_t[:act_as_project_type].not_eq(nil).
          and(p_t[:act_as_project_type].not_eq(p_t[:ProjectType]))
        ).
        order(ds_t[:short_name].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/project_type_reconciliation')
    end
  end
end
