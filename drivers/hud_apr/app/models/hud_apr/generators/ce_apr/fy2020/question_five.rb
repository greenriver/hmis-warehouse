###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::CeApr::Fy2020
  class QuestionFive < HudApr::Generators::Shared::Fy2020::QuestionFive
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBER = 'Q5a'
  end
end
