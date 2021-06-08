###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionEightToSixteen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 8 to 16'.freeze
    QUESTION_TABLE_NUMBER = 'Q8-Q16'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Persons served during this reporting period:',
      'Count',
    ].freeze
    ROW_LABELS = [
      '8. Number of persons contacted by PATH-funded staff this reporting period',
      '9. Number of new persons contacted this reporting period in a PATH Street Outreach project',
      '10. Number of new persons contacted this reporting period in a PATH Services Only project',
      '11. Total number of new persons contacted this reporting period (#9 + #10 = total new clients contacted)',
      '12a. Instances of contact this reporting period prior to date of enrollment',
      '12b. Total instances of contact during the reporting period',
      '13a. Number of new persons contacted this reporting period who could not be enrolled because of ineligibility for PATH',
      '13b. Number of new persons contacted this reporting period who could not be enrolled because provider was unable to locate the client',
      '14. Number of new persons contacted this reporting period who became enrolled in PATH',
      '15. Number with active, enrolled PATH status at any point during the reporting period',
      '16. Number of active, enrolled PATH clients receiving community mental health services through any funding source at any point during the reporting period',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # answer = @report.answer(question: table_name, cell: 'B1')
      # members = universe.universe_members
      # answer.add_members(members)
      # answer.update(summary: members.count)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
