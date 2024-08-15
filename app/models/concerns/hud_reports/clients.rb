###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
        label_for(:dkptr) => column.in([8, 9]),
        'Data Not Collected' => column.eq(99).or(column.eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    # Calculate the head of household’s number of years in the project. This can be done using the same
    # algorithm as for calculating a client’s age as of a certain date. Use the client’s [project start date] and the
    # [report end date] as the two dates of comparison. This calculation is time-based, not service-based, so a
    # client with a [project start date] that is active for a year or longer in a night-by-night emergency shelter
    # would require an Annual Assessment, regardless of how many bed night dates were recorded. It is
    # important to use the “age” method of determining client anniversaries due to leap years; using “one year =
    # 365 days” will eventually incorrectly offset the calculated anniversaries of long-term stayers.
    private def annual_assessment_expected?(enrollment:, report_end_date: Date.current)
      return false unless enrollment.present? && enrollment.head_of_household?

      start_for_annual = enrollment.entry_date
      end_date = [enrollment.last_date_in_program, report_end_date].compact.min
      # Get difference in years, ignoring month/date
      years_in_project = end_date.year - start_for_annual.year
      # Remove 1 year if month/date of start is after the month/date of the end date. This will account for leap years.
      years_in_project -= 1 if start_for_annual + years_in_project.years > end_date

      years_in_project > 0
    end

    private def annual_assessment_in_window?(enrollment, assessment_date)
      enrollment_date = enrollment.first_date_in_program
      return nil if assessment_date.nil?

      anniversary_date = anniversary_date(entry_date: enrollment_date, report_end_date: @report.end_date)
      assessment_date.between?(anniversary_date - 30.days, [anniversary_date + 30.days, @report.end_date].min)
    end

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

    private def gender_identities
      gender_col = a_t[:gender_multi]
      {
        'Woman' => [2, gender_col.eq('0')],
        'Man' => [3, gender_col.eq('1')],
        'Culturally Specific Identity' => [4, gender_col.eq('2')],
        'Transgender' => [5, gender_col.eq('5')],
        'Non-Binary' => [6, gender_col.eq('4')],
        'Questioning' => [7, gender_col.eq('6')],
        'Different Identity' => [8, gender_col.eq('3')],

        'Woman/Man' => [9, gender_col.eq('0,1')],
        'Woman/Culturally Specific Identity' => [10, gender_col.eq('0,2')],
        'Woman/Transgender' => [11, gender_col.eq('0,5')],
        'Woman/Non-Binary' => [12, gender_col.eq('0,4')],
        'Woman/Questioning' => [13, gender_col.eq('0,6')],
        'Woman/Different Identity' => [14, gender_col.eq('0,3')],

        'Man/Culturally Specific Identity' => [15, gender_col.eq('1,2')],
        'Man/Transgender' => [16, gender_col.eq('1,5')],
        'Man/Non-Binary' => [17, gender_col.eq('1,4')],
        'Man/Questioning' => [18, gender_col.eq('1,6')],
        'Man/Different Identity' => [19, gender_col.eq('1,3')],

        'Culturally Specific Identity/Transgender' => [20, gender_col.eq('2,5')],
        'Culturally Specific Identity/Non-Binary' => [21, gender_col.eq('2,4')],
        'Culturally Specific Identity/Questioning' => [22, gender_col.eq('2,6')],
        'Culturally Specific Identity/Different Identity' => [23, gender_col.eq('2,3')],

        'Transgender/Non-Binary' => [24, gender_col.eq('5,4')],
        'Transgender/Questioning' => [25, gender_col.eq('5,6')],
        'Transgender/Different Identity' => [26, gender_col.eq('5,3')],

        'Non-Binary/Questioning' => [27, gender_col.eq('4,6')],
        'Non-Binary/Different Identity' => [28, gender_col.eq('4,3')],

        'Questioning/Different Identity' => [29, gender_col.eq('6,3')],
        # 2 or more commas
        'More than 2 Gender Identities Selected' => [30, gender_col.matches_regexp('(\d+,){2,}')],
        label_for(:dkptr) => [31, gender_col.in(['8', '9'])],
        'Data Not Collected' => [32, gender_col.eq('99')],
        'Total' => [33, Arel.sql('1=1')],
      }.freeze
    end
  end
end
