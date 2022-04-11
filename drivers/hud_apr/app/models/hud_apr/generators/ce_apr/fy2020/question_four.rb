###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionFour < HudApr::Generators::Shared::Fy2020::QuestionFour
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze
  end
end
