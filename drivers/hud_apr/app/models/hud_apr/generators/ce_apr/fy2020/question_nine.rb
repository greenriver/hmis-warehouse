###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionNine < HudApr::Generators::Shared::Fy2020::QuestionNine
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      contact_counts = q9a_contacted
      q9b_engaged(contact_counts)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
