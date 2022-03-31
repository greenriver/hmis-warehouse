###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionThirteen < HudApr::Generators::Shared::Fy2020::QuestionThirteen
    QUESTION_TABLE_NUMBERS = [
      'Q13a1',
      'Q13b1',
      'Q13c1',
      'Q13a2',
      'Q13b2',
      'Q13c2',
    ].freeze
  end
end
