###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Unit < HmisBase
  include ArelHelper
  self.table_name = :hmis_units

  belongs_to :inventory, class_name: 'Hmis::Hud::Inventory'
  has_many :beds
  has_many :active_ranges, class_name: 'Hmis::ActiveRange', as: :entity

  scope :active, ->(date = Date.today) do
    active_unit = ar_t[:end].eq(nil).or(ar_t[:end].gteq(date))
    active_inventory = i_t[:inventory_end_date].eq(nil).or(i_t[:inventory_end_date].gteq(date))

    joins(:inventory).left_outer_joins(:active_ranges).where(active_unit.and(active_inventory))
  end

  scope :inactive, ->(date = Date.today) do
    inactive_unit = ar_t[:end].not_eq(nil).and(ar_t[:end].lt(date))
    inactive_inventory = i_t[:inventory_end_date].not_eq(nil).and(i_t[:inventory_end_date].lt(date))

    joins(:inventory).left_outer_joins(:active_ranges).where(inactive_unit.or(inactive_inventory))
  end

  def start_date
    Hmis::ActiveRange.for_entity(self)&.start || inventory.inventory_start_date
  end

  def end_date
    Hmis::ActiveRange.for_entity(self)&.end || inventory.inventory_end_date
  end

  def bed_count
    beds&.count || 0
  end
end
