module GrdaWarehouse
  class CasHoused < GrdaWarehouseBase
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    scope :unprocessed, -> do
      where inactivated: false
    end

    def self.inactivate_clients
      unprocessed.each do |cas_housed|
        cas_housed.client&.inactivate_in_cas()
      end
    end
  end
end