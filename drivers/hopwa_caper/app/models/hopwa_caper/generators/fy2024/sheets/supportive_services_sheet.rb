###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class SupportiveServicesSheet < Base
    QUESTION_NUMBER = 'Q6: SupportiveServices'.freeze
    QUESTION_TABLE_NUMBERS = [
      Q6 = 'Q6'.freeze,
    ].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)
      question_sheet(question: Q6) do |sheet|
        populate_sheet(sheet)
      end
      @report.complete(QUESTION_NUMBER)
    end

    def populate_sheet(sheet)
    end
  end
end
