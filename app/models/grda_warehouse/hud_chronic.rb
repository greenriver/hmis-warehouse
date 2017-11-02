module GrdaWarehouse
  class HudChronic < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :hud_chronics, required: true

    validates_presence_of :date

    scope :on_date, -> (date:) do
      where(date: date)
    end
  end
end
