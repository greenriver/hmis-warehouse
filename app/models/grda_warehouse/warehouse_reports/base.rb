module GrdaWarehouse::WarehouseReports
  class Base < GrdaWarehouseBase
    self.table_name = :warehouse_reports
    scope :ordered, -> { order(created_at: :desc) }

    scope :for_list, -> do
      select(column_names - ['data'])
    end
  end
end