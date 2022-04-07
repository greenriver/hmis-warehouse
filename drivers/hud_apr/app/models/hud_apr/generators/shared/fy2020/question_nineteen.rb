###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionNineteen < Base
    QUESTION_NUMBER = 'Question 19'.freeze

    def self.table_descriptions
      {
        'Question 19' => 'Cash Income – Changes over Time',
        'Q19a1' => 'Client Cash Income Change - Income Source - by Start and Latest Status',
        'Q19a2' => 'Client Cash Income Change - Income Source - by Start and Exit',
        'Q19b' => 'Disabling Conditions and Income for Adults at Exit',
      }.freeze
    end
  end
end
