###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    # NOTE: these are similar to living_situations but have slighting different coding and labels
    private def destination_clauses
      field = a_t[:destination]
      [
        ['Homeless Situations', nil],
        ['Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', field.eq(116)],
        ['Emergency shelter, including hotel or motel paid for with emergency shelter voucher, Host Home shelter', field.eq(101)],
        ['Safe Haven', field.eq(118)],
        ['Subtotal', field.in([101, 116, 118])],

        ['Institutional Situations', nil],
        ['Foster care home or foster care group home', field.eq(215)],
        ['Hospital or other residential non-psychiatric medical facility', field.eq(206)],
        ['Jail, prison or juvenile detention facility', field.eq(207)],
        ['Long-term care facility or nursing home', field.eq(225)],
        ['Psychiatric hospital or other psychiatric facility', field.eq(204)],
        ['Substance abuse treatment facility or detox center', field.eq(205)],
        ['Subtotal', field.in([215, 206, 207, 225, 204, 205])],

        ['Temporary Situations', nil],
        ['Transitional housing for homeless persons (including homeless youth)', field.eq(302)],
        ['Residential project or halfway house with no homeless criteria', field.eq(329)],
        ['Hotel or motel paid for without emergency shelter voucher', field.eq(314)],
        ['Host Home (non-crisis)', field.eq(332)],
        ['Staying or living with family, temporary tenure (e.g., room, apartment, or house)', field.eq(312)],
        ['Staying or living with friends, temporary tenure (e.g., room, apartment, or house)', field.eq(313)],
        ['Moved from one HOPWA funded project to HOPWA TH ', field.eq(327)],
        ['Subtotal', field.in([302, 329, 314, 332, 312, 313, 327])],

        ['Permanent Situations', nil],
        ['Staying or living with family, permanent tenure', field.eq(422)],
        ['Staying or living with friends, permanent tenure', field.eq(423)],
        ['Moved from one HOPWA funded project to HOPWA PH', field.eq(426)],
        ['Rental by client, no ongoing housing subsidy', field.eq(410)],
        ['Rental by client, with ongoing housing subsidy', field.eq(435)],
        ['Owned by client, with ongoing housing subsidy', field.eq(421)],
        ['Owned by client, no ongoing housing subsidy', field.eq(411)],
        ['Subtotal', field.in([422, 423, 426, 410, 435, 421, 411])],

        ['Other Situations', nil],
        ['No Exit Interview completed', field.eq(30)],
        ['Other', field.eq(17)],
        ['Deceased', field.eq(24)],
        [label_for(:dkptr), field.in([8, 9])],
        [label_for(:data_not_collected), field.eq(99).or(field.eq(nil))],
        ['Subtotal', field.in([8, 9, 17, 24, 30, 99]).or(field.eq(nil))],
        ['TOTAL', leavers_clause],
        [
          'Total persons exiting to positive housing destinations',
          a_t[:project_type].in([0, 1, 2]).
            and(a_t[:destination].in(positive_destinations(1))).
            or(a_t[:project_type].eq(4).and(a_t[:destination].in(positive_destinations(4)))).
            or(a_t[:project_type].not_in([0, 1, 2, 4]).and(a_t[:destination].in(positive_destinations(8)))),
        ],
        [
          'Total persons whose destinations excluded them from the calculation',
          a_t[:project_type].not_eq(4).
            and(a_t[:destination].in(excluded_destinations(1))).
            or(a_t[:project_type].eq(4).and(a_t[:destination].in(excluded_destinations(4)))),
        ],
        [
          'Percentage of persons exiting to positive housing destinations',
          :percentage,
        ],
      ]
    end

    private def positive_destinations(project_type)
      # From Appendix A: Exit Destinations: https://files.hudexchange.info/resources/documents/FY24-HMIS-Programming-Specifications-CoC-APR-and-ESG-CAPER.pdf
      positive_permanent_destinations = [426, 411, 421, 410, 435, 422, 423]
      case project_type
      when 4
        [101, 118] +
        [215, 204, 205, 225] +
        [314, 312, 313, 302, 327, 332] +
        positive_permanent_destinations
      when 0, 1, 2
        [332] +
        positive_permanent_destinations
      else
        positive_permanent_destinations
      end
    end

    private def excluded_destinations(project_type)
      case project_type
      when 4
        [206, 329, 24]
      else
        [215, 206, 225, 24]
      end
    end
  end
end
