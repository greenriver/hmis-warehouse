###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionSix < HudApr::Generators::Shared::Fy2024::QuestionSix
    QUESTION_TABLE_NUMBERS = ('Q6a'..'Q6f').to_a.freeze

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
