###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
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
        'Client Doesn’t Know/Client Refused' => column.in([8, 9]),
        'Data Not Collected' => column.eq(99).or(column.eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    private def ethnicities
      {
        '0' => {
          order: 1,
          label: 'Non-Hispanic/Non-Latino',
          clause: a_t[:ethnicity].eq(0),
        },
        '1' => {
          order: 2,
          label: 'Hispanic/Latino',
          clause: a_t[:ethnicity].eq(1),
        },
        '8 or 9' => {
          order: 3,
          label: 'Client Doesn’t Know/Client Refused',
          clause: a_t[:ethnicity].in([8, 9]),
        },
        '99' => {
          order: 4,
          label: 'Data Not Collected',
          clause: a_t[:ethnicity].eq(99).or(a_t[:ethnicity].eq(nil)),
        },
        'Total' => {
          order: 5,
          label: 'Total',
          clause: Arel.sql('1=1'),
        },
      }.sort_by { |_, m| m[:order] }.freeze
    end

    private def disability_clauses(suffix)
      {
        'Mental Health Problem' => a_t["mental_health_problem_#{suffix}".to_sym].eq(1),
        'Alcohol Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(false)),
        'Drug Abuse' => a_t["drug_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["alcohol_abuse_#{suffix}".to_sym].eq(false)),
        'Both Alcohol and Drug Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(true)),
        'Chronic Health Condition' => a_t["chronic_disability_#{suffix}".to_sym].eq(1),
        'HIV/AIDS' => a_t["hiv_aids_#{suffix}".to_sym].eq(1),
        'Developmental Disability' => a_t["developmental_disability_#{suffix}".to_sym].eq(1),
        'Physical Disability' => a_t["physical_disability_#{suffix}".to_sym].eq(1),
      }
    end

    private def annual_assessment_expected?(enrollment)
      return false if enrollment.last_date_in_program.present? &&
        enrollment.last_date_in_program - enrollment.first_date_in_program < 1.year

      enrollment.head_of_household? && enrollment.first_date_in_program + 1.years < report_end_date
    end

    private def annual_assessment_in_window?(enrollment, assessment_date)
      enrollment_date = enrollment.first_date_in_program
      return nil if assessment_date.nil?

      begin
        anniversary_date = Date.new(report_end_date.year, enrollment_date.month, enrollment_date.day)
      rescue Date::Error
        # If a client was enrolled on 2/29 of a leap year, non-leap years will throw invalid date
        # Make the anniversary fall on the last day of Feb to be consistent with Date.new(...) + 1.year
        if enrollment_date.month == 2 && enrollment_date.day == 29
          anniversary_date = Date.new(report_end_date.year, 2, 28)
        else
          return nil
        end
      end

      anniversary_date -= 1.year if anniversary_date > report_end_date
      return nil if anniversary_date < enrollment_date

      assessment_date.between?(anniversary_date - 30.days, anniversary_date + 30.days)
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
