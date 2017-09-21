module GrdaWarehouse
  class UserClient < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid
    
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user
  end
end
