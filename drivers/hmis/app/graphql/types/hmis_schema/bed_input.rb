###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::BedInput < BaseInputObject
    def self.source_type
      HmisSchema::Inventory
    end

    argument :inventory_id, ID
    argument :unit_id, ID, 'Unit to assign beds to'
    hud_argument :ch_vet_bed_inventory
    hud_argument :youth_vet_bed_inventory
    hud_argument :vet_bed_inventory
    hud_argument :ch_youth_bed_inventory
    hud_argument :youth_bed_inventory
    hud_argument :ch_bed_inventory
    hud_argument :other_bed_inventory
  end
end
