###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Unit < ::GrdaWarehouseBase
  self.table_name = :hmis_units
  belongs_to :inventory, class_name: 'Hmis::Hud::Inventory'
  has_many :beds

  def start_date
    Hmis::ActiveRange.for_entity(self)&.start || inventory.inventory_start_date
  end

  def end_date
    Hmis::ActiveRange.for_entity(self)&.end || inventory.inventory_end_date
  end
end
