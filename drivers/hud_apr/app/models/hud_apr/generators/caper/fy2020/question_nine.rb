###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionNine < HudApr::Generators::Shared::Fy2020::QuestionNine
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b'].freeze
  end
end
