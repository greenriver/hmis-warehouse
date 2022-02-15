###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q10'].freeze

    def self.table_descriptions
      {
        'Question 10' => 'Total Coordinated Entry Activity During the Year',
        'Q10' => 'Total Coordinated Entry Activity During the Year',
      }.freeze
    end

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q10_total_coordinated_entry

      @report.complete(QUESTION_NUMBER)
    end

    private def ce_a_t
      @ce_a_t ||= HudApr::Fy2020::CeAssessment.arel_table
    end

    private def ce_e_t
      @ce_e_t ||= HudApr::Fy2020::CeEvent.arel_table
    end

    private def columns
      {
        'B' => Arel.sql('1=1'),
        'C' => ce_e_t[:referral_result].eq(1),
        'D' => ce_e_t[:referral_result].eq(2),
        'E' => ce_e_t[:referral_result].eq(3),
        'F' => ce_e_t[:problem_sol_div_rr_result].eq(1),
        'G' => ce_e_t[:referral_case_manage_after].eq(1),
      }
    end

    private def col_headers
      [
        'Assessment/Event',
        'Total Occurrences',
        'Successful Referral',
        'Unsuccessful Referral: client rejected',
        'Unsuccessful Referral: provider rejected',
        'Re-housed in safe alternative',
        'Enrolled in aftercare',
      ]
    end

    private def intentionally_blank
      [
        'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12',
        'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10', 'D11', 'D12',
        'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10', 'E11', 'E12',
        'F2', 'F3', 'F4', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17', 'F18',
        'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G9', 'G10', 'G11', 'G12', 'G13', 'G14', 'G15', 'G16', 'G17', 'G18'
      ]
    end

    private def q10_table_rows
      {
        'Crisis Needs Assessment' => ce_a_t[:assessment_level].eq(1),
        'Housing Needs Assessment' => ce_a_t[:assessment_level].eq(2),
        'Referral to Prevention Assistance project' => ce_e_t[:event].eq(1),
        'Problem Solving/Diversion/Rapid Resolution intervention or service' => ce_e_t[:event].eq(2),
        'Referral to scheduled Coordinated Entry Crisis Needs Assessment' => ce_e_t[:event].eq(3),
        'Referral to scheduled Coordinated Entry Housing Needs Assessment' => ce_e_t[:event].eq(4),
        'Referral to post-placement/follow-up case management' => ce_e_t[:event].eq(5),
        'Referral to Street Outreach project or services' => ce_e_t[:event].eq(6),
        'Referral to Housing Navigation project or services' => ce_e_t[:event].eq(7),
        'Referral to Non-continuum services: Ineligible for continuum services' => ce_e_t[:event].eq(8),
        'Referral to Non continuum services: No availability in continuum services' => ce_e_t[:event].eq(9),
        'Referral to Emergency Shelter bed opening' => ce_e_t[:event].eq(10),
        'Referral to Transitional Housing bed/unit opening' => ce_e_t[:event].eq(11),
        'Referral to Joint TH-RRH project/unit/resource opening' => ce_e_t[:event].eq(12),
        'Referral to RRH project resource opening' => ce_e_t[:event].eq(13),
        'Referral to PSH project resource opening' => ce_e_t[:event].eq(14),
        'Referral to Other PH project/unit/resource opening' => ce_e_t[:event].eq(15),
      }.freeze
    end

    private def q10_total_coordinated_entry
      table_name = 'Q10'

      metadata = {
        header_row: col_headers,
        row_labels: q10_table_rows.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 18,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      columns.each do |col, columns_clause|
        q10_table_rows.each_value.with_index do |row_clause, row|
          row_num = (row + metadata[:first_row]).to_s
          cell = "#{col}#{row_num}"

          next if cell.in?(intentionally_blank)

          # rows 2 and 3 only require assessments
          # all others require events
          joins = if row_num.in?(assessment_only_rows)
            { ce_apr_client: :hud_report_ce_assessments }
          else
            { ce_apr_client: :hud_report_ce_events }
          end
          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.
            joins(joins).
            where(columns_clause).
            where(row_clause)
          answer.add_members(members)
          # TODO: confirm this only adds members once, but counts them for each assessment/event
          answer.update(summary: members.count)
        end
      end
    end

    private def assessment_only_rows
      [
        '2',
        '3',
      ].freeze
    end
  end
end
