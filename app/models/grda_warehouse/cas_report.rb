module GrdaWarehouse
  # gets dumped into by CAS
  class CasReport < GrdaWarehouseBase
    def readonly?
      true
    end
  end
end