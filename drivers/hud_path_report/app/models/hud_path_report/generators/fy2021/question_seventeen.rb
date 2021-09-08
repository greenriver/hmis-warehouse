###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class QuestionSeventeen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q17: Services Provided'.freeze
    QUESTION_TABLE_NUMBER = 'Q17'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Type of Service',
      'Number of people receiving service',
    ].freeze

    ROWS = {
      '17a. Reengagement' => 1,
      '17b. Screening' => 2,
      '17c. Clinical Assessment' => 14,
      '17d. Habilitation/rehabilitation' => 3,
      '17e. Community mental health' => 4,
      '17f. Substance use treatment' => 5,
      '17g. Case management' => 6,
      '17h. Residential supportive services' => 7,
      '17i. Housing minor renovation' => 8,
      '17j. Housing moving assistance' => 9,
      '17k. Housing eligibility determination' => 10,
      '17l. Security deposits' => 11,
      '17m. One-time rent for eviction prevention' => 12,
    }.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROWS.keys,
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 14,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      ROWS.values.each_with_index do |service, index|
        answer = @report.answer(question: table_name, cell: 'B' + (index + 2).to_s)
        members = universe.members.where(active_and_enrolled_clients).where(received_service(service))
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      @report.complete(QUESTION_NUMBER)
    end
  end
end
