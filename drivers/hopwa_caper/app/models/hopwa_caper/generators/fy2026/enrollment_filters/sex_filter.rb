###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  SexFilter = Struct.new(:label, :code, keyword_init: true) do
    def apply(scope) = scope.where(sex: code)

    def self.all
      filters = [
        new(label: 'Female', code: 0),
        new(label: 'Male', code: 1),
      ]

      filters + [ExcludeFilter.new(label: 'Sex not reported', filters: filters)]
    end
  end
end
