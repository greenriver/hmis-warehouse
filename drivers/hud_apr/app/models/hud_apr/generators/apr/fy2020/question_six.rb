###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionSix < HudApr::Generators::Shared::Fy2020::QuestionSix
    include ArelHelper

    QUESTION_NUMBER = 'Question 6'.freeze
    QUESTION_TABLE_NUMBERS = ('Q6a'..'Q6f').to_a.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q6a_pii
      q6b_universal_data_elements
      q6c_income_and_housing
      q6d_chronic_homelessness
      q6e_timeliness
      q6f_inactive_records

      @report.complete(QUESTION_NUMBER)
    end
  end
end
