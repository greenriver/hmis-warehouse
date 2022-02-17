###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class Children < Base
    QUESTION_NUMBER = 'Households with only Children'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |row| row[:household_type] == :children_only }
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_NUMBER])

      # q18_income

      @report.complete(QUESTION_NUMBER)
    end
  end
end
