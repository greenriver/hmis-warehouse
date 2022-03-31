###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentySeven < HudApr::Generators::Shared::Fy2020::QuestionTwentySeven
    QUESTION_TABLE_NUMBERS = ['Q27a', 'Q27b', 'Q27c', 'Q27d', 'Q27e', 'Q27f', 'Q27g', 'Q27h', 'Q27i'].freeze
  end
end
