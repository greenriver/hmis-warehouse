###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
#
# Required accessors:
#   a_t: Arel Type for the universe model
#
# Required universe fields:
#   destination: Integer (HUD destination codes)
#   project_type: Integer (HUD project type codes)
#
module HudReports::Destinations
  extend ActiveSupport::Concern

  included do
    private def destination_clauses
      {
        'Permanent Destinations' => nil,
        'Moved from one HOPWA funded project to HOPWA PH' => a_t[:destination].eq(26),
        'Owned by client, no ongoing housing subsidy' => a_t[:destination].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:destination].eq(21),
        'Rental by client, no ongoing housing subsidy' => a_t[:destination].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:destination].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:destination].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:destination].eq(20),
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:destination].eq(3),
        'Staying or living with family, permanent tenure' => a_t[:destination].eq(22),
        'Staying or living with friends, permanent tenure' => a_t[:destination].eq(23),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:destination].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:destination].eq(33),
        'Rental by client in a public housing unit' => a_t[:destination].eq(34),
        'Subtotal - Permanent' => a_t[:destination].in([26, 11, 21, 10, 19, 28, 20, 3, 22, 23, 31, 33, 34]),
        'Temporary Destinations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:destination].eq(1),
        'Moved from one HOPWA funded project to HOPWA TH' => a_t[:destination].eq(27),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:destination].eq(2),
        'Staying or living with family, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(12),
        'Staying or living with friends, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(13),
        'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)' => a_t[:destination].eq(16),
        'Safe Haven' => a_t[:destination].eq(18),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:destination].eq(14),
        'Host Home (non-crisis)' => a_t[:destination].eq(32),
        'Subtotal - Temporary' => a_t[:destination].in([1, 27, 2, 12, 13, 16, 18, 14, 32]),
        'Institutional Settings' => nil,
        'Foster care home or group foster care home' => a_t[:destination].eq(15),
        'Psychiatric hospital or other psychiatric facility' => a_t[:destination].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:destination].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:destination].eq(6),
        'Jail, prison, or juvenile detention facility' => a_t[:destination].eq(7),
        'Long-term care facility or nursing home' => a_t[:destination].eq(25),
        'Subtotal - Institutional' => a_t[:destination].in([15, 4, 5, 6, 7, 25]),
        'Other Destinations' => nil,
        'Residential project or halfway house with no homeless criteria' => a_t[:destination].eq(29),
        'Deceased' => a_t[:destination].eq(24),
        'Other' => a_t[:destination].eq(17),
        "Client Doesn't Know/Client Refused" => a_t[:destination].in([8, 9]),
        'Data Not Collected (no exit interview completed)' => a_t[:destination].in([30, 99]),
        'Subtotal - Other' => a_t[:destination].in([29, 24, 17, 8, 9, 30, 99]),
        'Total' => leavers_clause,
        'Total persons exiting to positive housing destinations' => a_t[:project_type].in([1, 2]).
          and(a_t[:destination].in(positive_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(positive_destinations(4)))).
          or(a_t[:project_type].not_in([1, 2, 4]).and(a_t[:destination].in(positive_destinations(8)))),
        'Total persons whose destinations excluded them from the calculation' => a_t[:project_type].not_eq(4).
          and(a_t[:destination].in(excluded_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(excluded_destinations(4)))),
        'Percentage' => :percentage,
      }.freeze
    end

    private def positive_destinations(project_type)
      case project_type
      when 4
        [1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      when 1, 2
        [32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      else
        [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      end
    end

    private def excluded_destinations(project_type)
      case project_type
      when 4
        [6, 29, 24]
      else
        [15, 6, 25, 24]
      end
    end
  end
end
