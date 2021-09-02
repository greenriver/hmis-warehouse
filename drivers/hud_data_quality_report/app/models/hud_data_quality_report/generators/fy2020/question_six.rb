###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionSix < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 6'.freeze
    QUESTION_TABLE_NUMBER = 'Q6'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 6' => 'Timeliness',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: [
          'Time for Record Entry',
          'Number of Project Start Records',
          'Number of Project Exit Records',
        ],
        row_labels: [
          '0 days',
          '1-3 days',
          '4-6 days',
          '7-10 days',
          '11+ days',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      arrivals = universe.members.where(a_t[:first_date_in_program].gteq(@report.start_date))

      [
        # entry on date
        {
          cell: 'B2',
          clause: a_t[:first_date_in_program].eq(a_t[:enrollment_created]),
        },
        # entry 1..3 days
        {
          cell: 'B3',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(1).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(3)),
        },
        # entry 4..6 days
        {
          cell: 'B4',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'B5',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'B6',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = arrivals.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      leavers = universe.members.where.not(a_t[:last_date_in_program].eq(nil))

      [
        # exit on date
        {
          cell: 'C2',
          clause: a_t[:last_date_in_program].eq(a_t[:exit_created]),
        },
        # exit 1..3 days
        {
          cell: 'C3',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(1).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(3)),
        },
        # exit 4..6 days
        {
          cell: 'C4',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'C5',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'C6',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = leavers.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      @report.complete(QUESTION_NUMBER)
    end
  end
end
