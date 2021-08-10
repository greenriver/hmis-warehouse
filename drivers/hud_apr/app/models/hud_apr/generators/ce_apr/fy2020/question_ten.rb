###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    QUESTION_TABLE_NUMBERS = ['Q10'].freeze

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
        'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11',
        'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10', 'D11',
        'E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7', 'E8', 'E9', 'E10', 'E11',
        'F1', 'F2', 'F3', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'F13', 'F14', 'F15', 'F16', 'F17',
        'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G8', 'G9', 'G10', 'G11', 'G12', 'G13', 'G14', 'G15', 'G16', 'G17'
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
          cell = "#{col}#{row + metadata[:first_row]}"
          next if cell.in?(intentionally_blank)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            joins(:hud_report_ce_assessments, :hud_report_ce_events).
            where(columns_clause).
            where(row_clause)
          answer.add_members(members)
          # TODO: confirm this only adds members once, but counts them for each assessment/event
          answer.update(summary: members.count)
        end
      end
    end
  end
end
