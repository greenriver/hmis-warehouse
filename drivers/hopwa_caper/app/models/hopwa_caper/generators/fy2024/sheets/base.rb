# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class Base < ::HudReports::QuestionBase
    READ_ONLY_MESSAGE = HopwaCaper::Generators::Fy2024::Generator::UNSUPPORTED_MESSAGE

    def run_question!
      raise NotImplementedError, READ_ONLY_MESSAGE
    end
  end
end
