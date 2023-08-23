###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Exit
  class UpdateDestination
    DESTINATIONS = {
      16 => 116,
      1 => 101,
      18 => 118,

      15 => 215,
      6 => 206,
      7 => 207,
      25 => 225,
      4 => 204,
      5 => 205,

      2 => 302,
      29 => 329,
      14 => 314,
      32 => 332,
      12 => 312,
      13 => 313,
      27 => 227,
      36 => 336,
      35 => 335,

      22 => 422,
      23 => 423,
      26 => 426,
      10 => 410,
      21 => 421,
      11 => 411,

      30 => 30,
      17 => 17,
      24 => 24,
      37 => 37,
      8 => 8,
      9 => 9,
      99 => 99,

      28 => 435,
      19 => 435,
      31 => 435,
      34 => 435,
      20 => 435,
      3 => 435,
    }.freeze

    def process(row)
      destination = row['Destination'].to_i
      new_destination = DESTINATIONS[destination]
      return row unless new_destination.present?

      row['Destination'] = new_destination

      row
    end
  end
end
