class MakeClientIncomesReportLimitable < ActiveRecord::Migration
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.
        find_by(name: 'Client Incomes').
        update(limitable: true)
  end

  def down
    GrdaWarehouse::WarehouseReports::ReportDefinition.
        find_by(name: 'Client Incomes').
        update(limitable: false)
  end
end
