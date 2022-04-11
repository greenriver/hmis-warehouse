###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2020::QuestionTwentyFive
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25e', 'Q25f', 'Q25g', 'Q25h', 'Q25i'].freeze
  end
end
