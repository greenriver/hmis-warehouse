###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionSix < HudApr::Generators::Shared::Fy2020::QuestionSix
    QUESTION_TABLE_NUMBERS = ('Q6a'..'Q6f').to_a.freeze
  end
end
