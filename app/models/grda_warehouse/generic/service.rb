module GrdaWarehouse::Generic
  class Service < GrdaWarehouseBase
    self.table_name = :generic_services

    belongs_to :client
    belongs_to :data_source
  end
end
