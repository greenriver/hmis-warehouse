###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionThirteen < HudApr::Generators::Shared::Fy2020::QuestionThirteen
    QUESTION_TABLE_NUMBERS = [
      'Q13a1',
      'Q13b1',
      'Q13c1',
    ].freeze
  end
end
