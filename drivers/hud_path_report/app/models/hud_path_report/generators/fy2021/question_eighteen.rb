###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class QuestionEighteen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q18: Referrals Provided'.freeze
    QUESTION_TABLE_NUMBER = 'Q18'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Type of Referral',
      'Number receiving each referral',
      'Number who attained the service from the referral',
    ].freeze

    ROWS = {
      'Community mental health' => 1,
      'Substance use treatment' => 2,
      'Primary health/dental care' => 3,
      'Job training' => 4,
      'Educational services' => 5,
      'Housing Services' => 6,
      'Temporary housing' => 11,
      'Permanent housing' => 7,
      'Income assistance' => 8,
      'Employment assistance' => 9,
      'Medical Insurance' => 10,
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
        last_column: 'C',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      ROWS.values.each_with_index do |referral, index|
        answer = @report.answer(question: table_name, cell: 'B' + (index + 2).to_s)
        members = universe.members.where(active_and_enrolled_clients).where(received_referral(referral))
        answer.add_members(members)
        answer.update(summary: members.count)

        answer = @report.answer(question: table_name, cell: 'C' + (index + 2).to_s)
        members = universe.members.where(active_and_enrolled_clients).where(service_from_referral(referral))
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      @report.complete(QUESTION_NUMBER)
    end

    def received_referral(referral)
      "jsonb_path_exists (#{a_t[:referrals].to_sql}, '$.*?(@[0]== #{referral})')"
    end

    def service_from_referral(referral)
      "jsonb_path_exists (#{a_t[:referrals].to_sql}, '$.*?(@[0]== #{referral} && @[1] == 1)')"
    end
  end
end
