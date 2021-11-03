###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CasHoused < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
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
