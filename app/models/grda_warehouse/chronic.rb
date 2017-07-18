module GrdaWarehouse
  class Chronic < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :chronics, required: true

    validates_presence_of :date

    scope :on_date, -> (date:) do
      where(date: date)
    end 

    def self.most_recent_day
      if self.count > 0
        self.maximum(:date)
      else
        Date.today
      end
    end
  end
end
