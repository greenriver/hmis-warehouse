###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::CeApr::Fy2020
  class QuestionSeven < HudApr::Generators::Shared::Fy2020::QuestionSeven
    include HudApr::Generators::CeApr::Fy2020::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q7a'].freeze
  end
end
