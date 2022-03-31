###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionNineteen < HudApr::Generators::Shared::Fy2020::QuestionNineteen
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2', 'Q19b'].freeze
  end
end
