class MakeClientIncomesReportLimitable < ActiveRecord::Migration[4.2]
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
