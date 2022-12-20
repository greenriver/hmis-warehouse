###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Bed < ::GrdaWarehouseBase
  self.table_name = :hmis_beds
  belongs_to :unit, class_name: 'Hmis::Unit'

  def start_date
    Hmis::ActiveRange.for_entity(self)&.start || unit.start_date
  end

  def end_date
    Hmis::ActiveRange.for_entity(self)&.end || unit.end_date
  end

  def self.bed_types
    [
      :ch_vet_bed_inventory,
      :youth_vet_bed_inventory,
      :vet_bed_inventory,
      :ch_youth_bed_inventory,
      :youth_bed_inventory,
      :ch_bed_inventory,
      :other_bed_inventory,
    ]
  end
end
