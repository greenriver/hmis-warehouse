###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::CeApr::Fy2020
  class QuestionEight < HudApr::Generators::Shared::Fy2020::QuestionEight
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q8a'].freeze
  end
end
