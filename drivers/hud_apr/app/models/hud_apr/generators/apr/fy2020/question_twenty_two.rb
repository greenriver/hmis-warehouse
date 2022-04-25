###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentyTwo < HudApr::Generators::Shared::Fy2020::QuestionTwentyTwo
    QUESTION_TABLE_NUMBERS = ['Q22a1', 'Q22b', 'Q22c', 'Q22e'].freeze
  end
end
