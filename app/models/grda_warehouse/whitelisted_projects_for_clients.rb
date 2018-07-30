module GrdaWarehouse
  class WhitelistedProjectsForClients < GrdaWarehouseBase
    has_one :data_source
    validates_presence_of :ProjectID, :data_source_id
  end
end
