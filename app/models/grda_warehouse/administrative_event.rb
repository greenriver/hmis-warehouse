module GrdaWarehouse
  class AdministrativeEvent < GrdaWarehouseBase
    self.table_name = :administrative_events
    acts_as_paranoid
    
    belongs_to :user
    
  end
end
