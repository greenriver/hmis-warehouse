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

    # override HudReports::Clients concern
    def yes_know_dkn_clauses(column)
      {
        'Yes' => column.eq(1),
        'No' => column.eq(0),
        label_for(:dkptr) => column.in([8, 9]),
        label_for(:data_not_collected) => column.eq(99).or(column.eq(nil)),
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

    # override HudReports::Clients concern
    def living_situations
      [
        ['Homeless Situations', nil],
        ['Place not meant for habitation', a_t[:prior_living_situation].eq(116)],
        ['Emergency shelter, including hotel or motel paid for with emergency shelter voucher, Host Home shelter', a_t[:prior_living_situation].eq(101)],
        ['Safe Haven', a_t[:prior_living_situation].eq(118)],
        ['Subtotal', a_t[:prior_living_situation].in([101, 116, 118])],

        ['Institutional Settings', nil],
        ['Foster care home or foster care group home', a_t[:prior_living_situation].eq(215)],
        ['Hospital or other residential non-psychiatric medical facility', a_t[:prior_living_situation].eq(206)],
        ['Jail, prison or juvenile detention facility', a_t[:prior_living_situation].eq(207)],
        ['Long-term care facility or nursing home', a_t[:prior_living_situation].eq(225)],
        ['Psychiatric hospital or other psychiatric facility', a_t[:prior_living_situation].eq(204)],
        ['Substance abuse treatment facility or detox center', a_t[:prior_living_situation].eq(205)],
        ['Subtotal', a_t[:prior_living_situation].in([215, 206, 207, 225, 204, 205])],

        ['Temporary Situation', nil],
        ['Transitional housing for homeless persons (including homeless youth)', a_t[:prior_living_situation].eq(302)],
        ['Residential project or halfway house with no homeless criteria', a_t[:prior_living_situation].eq(329)],
        ['Hotel or motel paid for without emergency shelter voucher', a_t[:prior_living_situation].eq(314)],
        ['Host Home (non-crisis)', a_t[:prior_living_situation].eq(332)],
        ["Staying or living in a friend's room, apartment or house", a_t[:prior_living_situation].eq(336)],
        ["Staying or living in a family member's room, apartment or house", a_t[:prior_living_situation].eq(335)],
        ['Subtotal', a_t[:prior_living_situation].in([302, 329, 314, 332, 336, 335])],

        ['Permanent Situations', nil],
        ['Rental by client, no ongoing housing subsidy', a_t[:prior_living_situation].eq(410)],
        ['Rental by client, with ongoing housing subsidy', a_t[:prior_living_situation].eq(435)],
        ['Owned by client, with ongoing housing subsidy', a_t[:prior_living_situation].eq(421)],
        ['Owned by client, no ongoing housing subsidy', a_t[:prior_living_situation].eq(411)],
        ['Subtotal', a_t[:prior_living_situation].in([410, 435, 421, 411])],

        [label_for(:dkptr), a_t[:prior_living_situation].in([8, 9])],
        [label_for(:data_not_collected), a_t[:prior_living_situation].eq(99).or(a_t[:prior_living_situation].eq(nil))],
        ['Subtotal', a_t[:prior_living_situation].in([8, 9, 99]).or(a_t[:prior_living_situation].eq(nil))],
        ['Total', Arel.sql('1=1')],
      ]
    end
  end
end
