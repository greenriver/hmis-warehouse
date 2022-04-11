###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    QUESTION_TABLE_NUMBERS = ['Q10a', 'Q10b', 'Q10c'].freeze
  end
end
