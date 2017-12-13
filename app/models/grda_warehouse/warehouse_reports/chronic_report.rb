module GrdaWarehouse::WarehouseReports
  class ChronicReport < Base
    scope :ordered, -> { order(created_at: :desc) }
  end
end