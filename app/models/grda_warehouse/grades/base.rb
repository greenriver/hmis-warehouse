module GrdaWarehouse
  class Base < GrdaWarehouseBase
    validates_presence_of :letter, :low
  end
end