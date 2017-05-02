module GrdaWarehouse
  class Chronic < GrdaWarehouseBase
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, inverse_of: :chronics, required: true

    validates_presence_of :date

    def self.most_recent_day
      self.maximum(:date)
    end
  end
end