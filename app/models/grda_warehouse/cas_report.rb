module GrdaWarehouse
  # gets dumped into by CAS
  class CasReport < GrdaWarehouseBase
    def readonly?
      true
    end
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :cas_reports
  end
end