module HudApr::Generators::Caper::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    include ArelHelper

    QUESTION_NUMBER = 'Question 10'.freeze
    QUESTION_TABLE_NUMBERS = ['Q10a', 'Q10b', 'Q10c', 'Q10d'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q10a_gender_of_adults
      q10b_gender_of_children
      q10c_gender_of_missing_age
      q10d_gender_by_age_range

      @report.complete(QUESTION_NUMBER)
    end
  end
end
