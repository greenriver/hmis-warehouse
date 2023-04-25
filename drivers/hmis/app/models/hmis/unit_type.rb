###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class UnitType < HmisBase
    # https://docs.google.com/spreadsheets/d/1xuXIohyPguAw10KcqlqiF23qgbNzKvAR/edit#gid=844425140

    # HUD bed types specified on Inventory
    enum(
      bed_type: {
        ch_vet_bed_inventory: 7,
        youth_vet_bed_inventory: 8,
        vet_bed_inventory: 9,
        ch_youth_bed_inventory: 10,
        youth_bed_inventory: 11,
        ch_bed_inventory: 12,
        other_bed_inventory: 13,
      },
    )

    include RailsDrivers::Extensions
  end
end
