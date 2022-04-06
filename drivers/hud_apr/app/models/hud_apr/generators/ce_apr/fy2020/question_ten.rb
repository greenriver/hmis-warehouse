###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q10'].freeze

    def self.table_descriptions
      {
        'Question 10' => 'Total Coordinated Entry Activity During the Year',
        'Q10' => 'Total Coordinated Entry Activity During the Year',
      }.freeze
    end
  end
end
