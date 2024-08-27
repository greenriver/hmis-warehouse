###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  LongevityFilter = Struct.new(:label, :range, keyword_init: true) do
    def apply(scope)
      # only look at hoh for durtion of enrollment
      scope.head_of_household.where(duration_days: range)
    end

    def self.all
      [
        new(label: 'less than one year', range: (...1.year.in_days)),
        new(label: 'more than one year, but less than five years', range: (1.year.in_days...5.year.in_days)),
        new(label: 'more than five years, but less than 10 years', range: (5.year.in_days...10.year.in_days)),
        new(label: 'more than 10 years, but less than 15 years', range: (10.year.in_days...15.year.in_days)),
        new(label: 'more than 15 years', range: (14.year.in_days..)),
      ]
    end
  end
end
