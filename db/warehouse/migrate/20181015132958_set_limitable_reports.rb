class SetLimitableReports < ActiveRecord::Migration
  def up
    unlimited_urls = [
      'warehouse_reports/cas/apr',
      'warehouse_reports/cas/canceled_matches',
      'warehouse_reports/cas/chronic_reconciliation',
      'warehouse_reports/cas/decision_efficiency',
      'warehouse_reports/cas/decline_reason',
      'warehouse_reports/cas/process',
      'warehouse_reports/manage_cas_flags',
      'warehouse_reports/chronic',
      'warehouse_reports/chronic_housed',
      'warehouse_reports/confidential_touch_point_exports',
      'warehouse_reports/consent',
      'warehouse_reports/expiring_consent',
      'warehouse_reports/find_by_id',
      'warehouse_reports/health/agency_performance',
      'warehouse_reports/health/claims',
      'warehouse_reports/health/member_status_reports',
      'warehouse_reports/health/overview',
      'warehouse_reports/hud_chronics',
      'warehouse_reports/non_alpha_names',
      'warehouse_reports/recidivism',
      'warehouse_reports/tableau_dashboard_export',
      'warehouse_reports/touch_point_exports',
      'warehouse_reports/missing_projects',
    ]
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: unlimited_urls).update_all(limitable: false)
  end
end
