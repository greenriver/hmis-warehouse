###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionSix < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionTwo
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionThree
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionFour
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionFive
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionSix
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionSeven

    QUESTION_NUMBER = 'Question 6'.freeze

    def self.table_descriptions
      {
        'Question 6' => 'Data Quality',
        'Q6a' => 'Data Quality: Personally Identifiable Information',
        'Q6b' => 'Data Quality: Universal Data Elements',
        'Q6c' => 'Data Quality: Income and Housing Data Quality',
        'Q6d' => 'Data Quality: Chronic Homelessness',
        'Q6e' => 'Data Quality: Timeliness',
        'Q6f' => 'Data Quality: Inactive Records: Street Outreach and Emergency Shelter',
      }.freeze
    end

    private def q6a_pii
      generate_q2('Q6a')
    end

    def q6b_universal_data_elements
      generate_q3('Q6b')
    end

    private def q6c_income_and_housing
      generate_q4('Q6c')
    end

    private def q6d_chronic_homelessness
      generate_q5('Q6d')
    end

    private def q6e_timeliness
      generate_q6('Q6e')
    end

    private def q6f_inactive_records
      generate_q7('Q6f')
    end
  end
end
