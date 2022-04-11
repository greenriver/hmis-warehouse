###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwelve < HudApr::Generators::Shared::Fy2020::QuestionTwelve
    QUESTION_TABLE_NUMBERS = ['Q12a', 'Q12b'].freeze
  end
end
