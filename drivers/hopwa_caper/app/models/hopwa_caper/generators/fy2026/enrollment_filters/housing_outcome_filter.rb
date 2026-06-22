###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# frozen_string_literal: true

# we might not need this, need specs around outcomes
module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  HousingOutcomeFilter = Struct.new(:label, :code, keyword_init: true) do
    def apply(scope)
      scope.where(housing_assessment_at_exit: code)
    end

    def self.all
      HudHelper.util('2026').housing_assessment_at_exits.map do |code, label|
        new(label: label, code: code)
      end
    end
  end
end
