###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  PriorLivingSituationFilter = Struct.new(:label, :codes, keyword_init: true) do
    def apply(scope)
      scope.where(prior_living_situation: codes)
    end

    MISSING_CODES = [8, 9, 99].freeze
    def self.all
      # FIXME: this is different from the PLS categories in the spec
      items = HudUtility2024.situations_for(:prior).map do |code, label|
        next if code.in?(MISSING_CODES)

        new(label: label, codes: [code])
      end.compact
      items.push new(label: "Doesn't know, prefers not to answer, or not collected", codes: MISSING_CODES)
    end
  end
end
