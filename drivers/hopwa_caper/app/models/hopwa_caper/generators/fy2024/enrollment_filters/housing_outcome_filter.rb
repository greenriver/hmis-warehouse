###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# we might not need this, need specs around outcomes
module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  HousingOutcomeFilter = Struct.new(:label, :code, keyword_init: true) do
    def apply(scope)
      scope.where(housing_assessment_at_exit: code)
    end

    def self.all
      HudUtility2024.housing_assessment_at_exits.map do |code, label|
        new(label: label, code: code)
      end
    end
  end
end
