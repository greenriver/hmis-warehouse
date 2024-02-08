###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour
  module LivingSituationOptions
    extend ActiveSupport::Concern

    LIVING_SITUATIONS = {
      16 => 116, # Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)
      1 => 101, # Emergency shelter, including hotel or motel paid for with emergency shelter voucher, Host Home shelter
      18 => 118, # Safe Haven

      15 => 215, # Foster care home or foster care group home
      6 => 206, # Hospital or other residential non-psychiatric medical facility
      7 => 207, # Jail, prison, or juvenile detention facility
      25 => 225, # Long-term care facility or nursing home
      4 => 204, # Psychiatric hospital or other psychiatric facility
      5 => 205, # Substance abuse treatment facility or detox center

      29 => 329, # Residential project or halfway house with no homeless criteria
      14 => 314, # Hotel or motel paid for without emergency shelter voucher
      2 => 302, # Transitional housing for homeless persons (including homeless youth)
      32 => 332, # Host Home (non-crisis)
      13 => 313, # Staying or living with friends, temporary tenure (e.g. room, apartment, or house)
      36 => 336, # Staying or living in a friend’s room, apartment, or house
      12 => 312, # Staying or living with family, temporary tenure (e.g. room, apartment, or house)
      # 22 in 400's
      35 => 335, # Staying or living in a family member’s room, apartment, or house
      # 23 in 400's
      # 26 in 400's
      27 => 327, # Moved from one HOPWA funded project to HOPWA TH

      # 28, 19, 3, 31, 33, 34 became 435
      22 => 422, # Staying or living with family, permanent tenure
      23 => 423, # Staying or living with friends, permanent tenure
      26 => 426, # Moved from one HOPWA funded project to HOPWA PH
      10 => 410, # Rental by client, no ongoing housing subsidy
      21 => 421, # Owned by client, with ongoing housing subsidy
      11 => 411, # Owned by client, no ongoing housing subsidy

      30 => 30, # No exit interview completed
      17 => 17, # Other
      24 => 24, # Deceased
      37 => 37, # Worker unable to determine
      8 => 8, # Client doesn’t know
      9 => 9, # Client prefers not to answer
      99 => 99, # Data not collected

      # These all become 435 - Rental by client, with ongoing housing subsidy
      28 => 435, # Rental by client, with GPD TIP housing subsidy
      19 => 435, # Rental by client, with VASH housing subsidy
      3 => 435, # Permanent housing (other than RRH) for formerly homeless persons
      31 => 435, # Rental by client, with RRH or equivalent subsidy
      33 => 435, # Rental by client, with HCV voucher (tenant or project based)
      34 => 435, # Rental by client in a public housing unit
      20 => 435, # Rental by client, with other ongoing housing subsidy
    }.freeze

    SUBSIDY_TYPES = {
      28 => 428, # GPD TIP housing subsidy
      19 => 419, # VASH housing subsidy
      31 => 431, # RRH or equivalent subsidy
      33 => 433, # HCV voucher (tenant or project based) (not dedicated)
      34 => 434, # Public housing unit
      20 => 420, # Rental by client, with other ongoing housing subsidy
      3 => 440, # Other permanent housing dedicated for formerly homeless persons
    }.freeze
  end
end
