###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionNine < HudApr::Generators::Shared::Fy2020::QuestionNine
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b', 'Q9c', 'Q9d'].freeze

    def self.table_descriptions
      {
        'Question 9' => 'Participation in Coordinated Entry',
        'Q9a' => 'Assessment Type - Households Assessed in the Date Range',
        'Q9b' => 'Prioritization Status - Households Prioritized in the Date Range',
        'Q9c' => 'Access Events - Households with an Access Event',
        'Q9d' => 'Referral Events - Households Who Were Referred',
      }.freeze
    end

    def needs_ce_assessments?
      true
    end
  end
end
