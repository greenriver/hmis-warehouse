###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class Generator < HudReports::GeneratorBase
    def initialize(options)
      super(options)
    end

    def self.title
      'Consolidated Annual Performance and Evaluation Report - FY 2020'
    end

    def self.questions
      [
        HudApr::Generators::Caper::Fy2020::QuestionTwentyTwo, # Length of participation
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end
  end
end
