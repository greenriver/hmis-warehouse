###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentySix < HudApr::Generators::Shared::Fy2020::QuestionTwentySix
    QUESTION_TABLE_NUMBERS = ['Q26a', 'Q26b', 'Q26c', 'Q26d', 'Q26e', 'Q26f', 'Q26g', 'Q26h'].freeze
  end
end
