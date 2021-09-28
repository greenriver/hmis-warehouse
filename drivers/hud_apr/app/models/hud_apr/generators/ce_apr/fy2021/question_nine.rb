###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class QuestionNine < HudApr::Generators::Shared::Fy2021::QuestionNine
    include HudApr::Generators::CeApr::Fy2021::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b', 'Q9c', 'Q9d'].freeze

    def self.table_descriptions
      {
        'Question 9' => 'Participation in Coordinated Entry',
        'Q9a' => 'Assessment Type - Households Assessed in the Date Range',
        'Q9b' => 'Prioritization Status - Households Prioritized in the Date Range',
        'Q9c' => 'Access Events - Households with an Access Event',
        'Q9d' => 'Referral Events - Households Who Were Referred',
      }.freeze
    end

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q9a_assessment_types
      q9b_prioritization_statuses
      q9c_access_events
      q9d_referral_events

      @report.complete(QUESTION_NUMBER)
    end

    private def columns
      {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_only),
        'D' => a_t[:household_type].eq(:adults_and_children),
        'E' => a_t[:household_type].eq(:children_only),
        'F' => a_t[:household_type].eq(:unknown),
      }
    end

    private def col_headers
      [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ]
    end

    private def q9a_table_rows
      {
        'Phone' => a_t[:ce_assessment_type].eq(1),
        'Virtual' => a_t[:ce_assessment_type].eq(2),
        'In-person' => a_t[:ce_assessment_type].eq(3),
        'Total Households Assessed' => a_t[:ce_assessment_type].in([1, 2, 3]),
      }.freeze
    end

    private def q9a_assessment_types
      table_name = 'Q9a'

      generate_table(table_name, q9a_table_rows, { last_row: 5 })
    end

    private def q9b_table_rows
      {
        'Placed on Prioritization List (Prioritized)' => a_t[:ce_assessment_prioritization_status].eq(1),
        'Not Placed on Prioritization List' => a_t[:ce_assessment_prioritization_status].eq(2),
        'Percent of Assessed Prioritized Of the total HH Assessed report the percent of those placed on the prioritization list' => Arel.sql('0=1'), # This will be calculated as a separate step
      }.freeze
    end

    private def q9b_prioritization_statuses
      table_name = 'Q9b'

      generate_table(table_name, q9b_table_rows, { last_row: 4 })

      # Populate row 3 with calculated values
      columns.each do |col, _|
        numerator = @report.answer(question: table_name, cell: "#{col}1").summary || 0
        denominator = numerator + (@report.answer(question: table_name, cell: "#{col}2").summary || 0)
        value = percentage(numerator / denominator.to_f)
        @report.answer(question: table_name, cell: "#{col}3").update(summary: value)
      end
    end

    private def q9c_table_rows
      {
        'Referral to Prevention Assistance project' => a_t[:ce_event_event].eq(1),
        'Problem Solving/Diversion/Rapid Resolution intervention or service' => a_t[:ce_event_event].eq(2),
        'Referral to scheduled Coordinated Entry Crisis Needs Assessment' => a_t[:ce_event_event].eq(3),
        'Referral to scheduled Coordinated Entry Housing Needs Assessment' => a_t[:ce_event_event].eq(4),
        'Total' => a_t[:ce_event_event].in((1..4).to_a),
        'Result: Client housed/Re-Housed in a safe alternative' => a_t[:ce_event_problem_sol_div_rr_result].eq(1),
        'Percent of successful referrals to Problem Solving/Diversion/Rapid Resolution' => Arel.sql('0=1'), # This will be calculated as a separate step
      }.freeze
    end

    private def q9c_access_events
      table_name = 'Q9c'

      generate_table(table_name, q9c_table_rows, { last_row: 8 })

      # Populate row 7 with calculated values
      columns.each do |col, _|
        numerator = @report.answer(question: table_name, cell: "#{col}2").summary || 0
        denominator = @report.answer(question: table_name, cell: "#{col}6").summary || 0
        value = percentage(numerator / denominator.to_f)
        @report.answer(question: table_name, cell: "#{col}7").update(summary: value)
      end
    end

    private def q9d_table_rows
      {
        'Post-placement/follow-up case management' => a_t[:ce_event_event].eq(5),
        'Street Outreach project or services' => a_t[:ce_event_event].eq(6),
        'Housing Navigation project or services' => a_t[:ce_event_event].eq(7),
        'Non-continuum services: Ineligible for continuum services' => a_t[:ce_event_event].eq(8),
        'Non continuum services: No availability in continuum services' => a_t[:ce_event_event].eq(9),
        'Emergency Shelter bed opening' => a_t[:ce_event_event].eq(10),
        'Transitional Housing bed/unit opening' => a_t[:ce_event_event].eq(11),
        'Joint TH-RRH project/unit/resource opening' => a_t[:ce_event_event].eq(12),
        'RRH project resource opening' => a_t[:ce_event_event].eq(13),
        'PSH project resource opening' => a_t[:ce_event_event].eq(14),
        'Other PH project' => a_t[:ce_event_event].eq(15),
        'Referral to emergency assistance/flex fund/furniture assistance' => a_t[:ce_event_event].eq(16),
        'Referral to Emergency Housing Voucher (EHV)' => a_t[:ce_event_event].eq(17),
        'Referral to a Housing Stability Voucher' => a_t[:ce_event_event].eq(18),
        'Total' => a_t[:ce_event_event].in((5..18).to_a),
        'Of the total HH prioritized (Q9b row 1) what percentage received a referral' => Arel.sql('0=1'), # This will be calculated as a separate step
        'Result: successful referral: client accepted' => a_t[:ce_event_referral_result].eq(1),
        'Result: Unsuccessful referral: client rejected' => a_t[:ce_event_referral_result].eq(2),
        'Result: Unsuccessful referral: provider rejected' => a_t[:ce_event_referral_result].eq(3),
        'No result recorded' => a_t[:ce_event_referral_result].eq(nil),
        'Result: Enrolled in Aftercare project' => a_t[:ce_event_referral_case_manage_after].eq(1),
        'Percent of successful referrals to residential projects' => Arel.sql('0=1'), # This will be calculated as a separate step
      }.freeze
    end

    private def q9d_referral_events
      table_name = 'Q9d'

      generate_table(table_name, q9d_table_rows, { last_row: 23 })

      # Populate rows 17 and 23 with calculated values (note spec is off by one)
      columns.each do |col, columns_clause|
        # denominator = Q9b row 1 (prioritized clients)
        members = universe.members.
          where(hoh_clause).
          where(columns_clause).
          where(a_t[:ce_assessment_prioritization_status].eq(1))
        denominator = members.count
        members = members.where(a_t[:ce_event_event].in((5..18).to_a))
        numerator = members.count
        value = percentage(numerator / denominator.to_f)
        answer = @report.answer(question: table_name, cell: "#{col}17")
        answer.update(summary: value)
        answer.add_members(members)

        # Row 23
        numerator = @report.answer(question: table_name, cell: "#{col}18").summary || 0
        denominator = [7, 8, 9, 10, 11, 12, 14, 15].map do |row_num|
          @report.answer(question: table_name, cell: "#{col}#{row_num}").summary || 0
        end.sum
        value = percentage(numerator / denominator.to_f)
        @report.answer(question: table_name, cell: "#{col}23").update(summary: value)
      end
    end

    private def generate_table(table_name, row_calculations, meta_overrides)
      metadata = {
        header_row: col_headers,
        row_labels: row_calculations.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 5,
      }.merge(meta_overrides)
      @report.answer(question: table_name).update(metadata: metadata)
      columns.each do |col, columns_clause|
        row_calculations.each_value.with_index do |row_clause, row|
          cell = "#{col}#{row + metadata[:first_row]}"
          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(hoh_clause).
            where(columns_clause).
            where(row_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end
  end
end
