module GrdaWarehouse::Confidence
  class DaysHomeless < ActiveRecord::Base
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    

  end
end