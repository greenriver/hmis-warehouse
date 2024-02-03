###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024::Dq::QuestionSix
  extend ActiveSupport::Concern

  included do
    private def generate_q6(table_name)
      metadata = {
        header_row: [
          'Time for Record Entry',
          'Number of Project Start Records',
          'Number of Project Exit Records',
        ],
        row_labels: [
          '< 0 days',
          '0 days',
          '1-3 days',
          '4-6 days',
          '7-10 days',
          '11+ days',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      universe_members = universe.members.where(engaged_clause)

      arrivals = universe_members.where(a_t[:first_date_in_program].gteq(@report.start_date))

      [
        {
          cell: 'B2',
          clause: a_t[:first_date_in_program].gt(a_t[:enrollment_created]).and(a_t[:first_date_in_program].gteq(@report.start_date)),
        },
        # entry on date
        {
          cell: 'B3',
          clause: a_t[:first_date_in_program].eq(a_t[:enrollment_created]),
        },
        # entry 1..3 days
        {
          cell: 'B4',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gt(0).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(3)),
        },
        # entry 4..6 days
        {
          cell: 'B5',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'B6',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'B7',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = arrivals.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      leavers = universe_members.where.not(a_t[:last_date_in_program].eq(nil))

      [
        {
          cell: 'C2',
          # It's possible we don't need the report start criteria, there's a current bug in the Test Kit
          # https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recQoBOA5VwRFp8jJ
          clause: a_t[:last_date_in_program].gt(a_t[:exit_created]).and(a_t[:exit_created].gteq(@report.start_date)),
        },
        # exit on date
        {
          cell: 'C3',
          clause: a_t[:last_date_in_program].eq(a_t[:exit_created]),
        },
        # exit 1..3 days
        {
          cell: 'C4',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gt(0).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(3)),
        },
        # exit 4..6 days
        {
          cell: 'C5',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'C6',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'C7',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = leavers.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end
  end
end
