###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionNine < HudApr::Generators::Shared::Fy2020::QuestionNine
    include ArelHelper

    QUESTION_NUMBER = 'Question 9'.freeze
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b'].freeze

    HEADER_ROW = [
      'Number of Persons Contacted',
      'All Persons Contacted',
      'First contact – NOT staying on the Streets, ES, or SH',
      'First contact – WAS staying on Streets, ES, or SH',
      'First contact – Worker unable to determine',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      contact_counts = q9a_contacted
      q9b_engaged(contact_counts)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
