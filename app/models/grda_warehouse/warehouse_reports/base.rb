module GrdaWarehouse::WarehouseReports
  class Base < GrdaWarehouseBase
    self.table_name = :warehouse_reports
    scope :ordered, -> { order(created_at: :desc) }
  end
end