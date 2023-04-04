###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
#   HudReports::Util for anniversary_date
#
# Required accessors:
#   a_t: Arel Type for the universe model
#
# Required universe fields:
#   ethnicity: Integer HUD ethnicity code
#   prior_living_situations: HUD codes
#   mental_health_problem_*, chronic_disability_*, hiv_aids_*, developmental_disability_*, physical_disability_*:
#     Integer: HUD yes/no
#   alcohol_abuse_*, drug_abuse_*: Boolean
#   Data collection phases are: entry, exit, latest
#
module HudReports::Clients
  extend ActiveSupport::Concern

  included do
    private def yes_know_dkn_clauses(column)
      {
        'Yes' => column.eq(1),
        'No' => column.eq(0),
        'Client Doesn\'t Know/Client Refused' => column.in([8, 9]),
        'Data Not Collected' => column.eq(99).or(column.eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    # Assessments are expected if:
    # You are the head of household.
    # If the enrollment lasted 365 days or more
    # and the reporting period end is 365 days or more since the beginning of the enrollment
    # and the enrollment started 365 days ago
    private def annual_assessment_expected?(enrollment)
      return false unless enrollment.present? && enrollment.head_of_household?

      end_date = [enrollment.last_date_in_program, report_end_date, Date.current].compact.min
      enough_days = if enrollment.project.bed_night_tracking?
        enrollment.enrollment.services.
          bed_night.between(start_date: enrollment.first_date_in_program, end_date: end_date).
          count >= 365
      else
        true
      end

      enrollment.first_date_in_program + 365.days <= end_date && enough_days
    end

    private def annual_assessment_in_window?(enrollment, assessment_date)
      enrollment_date = enrollment.first_date_in_program
      return nil if assessment_date.nil?

      anniversary_date = anniversary_date(entry_date: enrollment_date, report_end_date: @report.end_date)
      assessment_date.between?(anniversary_date - 30.days, [anniversary_date + 30.days, @report.end_date].min)
    end

    private def living_situations
      {
        'Homeless Situations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:prior_living_situation].eq(1),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:prior_living_situation].eq(2),
        'Place not meant for habitation' => a_t[:prior_living_situation].eq(16),
        'Safe Haven' => a_t[:prior_living_situation].eq(18),
        'Host Home (non-crisis)' => a_t[:prior_living_situation].eq(32),
        'Subtotal - Homeless' => a_t[:prior_living_situation].in([1, 2, 16, 18, 32]),
        'Institutional Settings' => nil,
        'Psychiatric hospital or other psychiatric facility' => a_t[:prior_living_situation].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:prior_living_situation].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:prior_living_situation].eq(6),
        'Jail, prison or juvenile detention facility' => a_t[:prior_living_situation].eq(7),
        'Foster care home or foster care group home' => a_t[:prior_living_situation].eq(15),
        'Long-term care facility or nursing home' => a_t[:prior_living_situation].eq(25),
        'Residential project or halfway house with no homeless criteria' => a_t[:prior_living_situation].eq(29),
        'Subtotal - Institutional' => a_t[:prior_living_situation].in([4, 5, 6, 7, 15, 25, 29]),
        'Other Locations' => nil,
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:prior_living_situation].eq(3),
        'Owned by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:prior_living_situation].eq(21),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:prior_living_situation].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:prior_living_situation].eq(33),
        'Rental by client in a public housing unit' => a_t[:prior_living_situation].eq(34),
        'Rental by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:prior_living_situation].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:prior_living_situation].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:prior_living_situation].eq(20),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:prior_living_situation].eq(14),
        "Staying or living in a friend's room, apartment or house" => a_t[:prior_living_situation].eq(36),
        "Staying or living in a family member's room, apartment or house" => a_t[:prior_living_situation].eq(35),
        'Client Doesn\'t Know/Client Refused' => a_t[:prior_living_situation].in([8, 9]),
        'Data Not Collected' => a_t[:prior_living_situation].eq(99).or(a_t[:prior_living_situation].eq(nil)),
        'Subtotal - Other' => a_t[:prior_living_situation].in(
          [
            3,
            11,
            21,
            31,
            33,
            34,
            10,
            19,
            28,
            20,
            14,
            36,
            35,
            8,
            9,
            99,
          ],
        ).or(a_t[:prior_living_situation].eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end
  end
end
