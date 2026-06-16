###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2020
  class QuestionTen < HudApr::Generators::Shared::Fy2020::QuestionTen
    QUESTION_TABLE_NUMBERS = ['Q10a', 'Q10b', 'Q10c', 'Q10d'].freeze
  end
end
