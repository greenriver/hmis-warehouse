###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  AgeFilter = Struct.new(:label, :range, keyword_init: true) do
    def label
      self[:label] || "#{range.begin}-#{range.end}"
    end

    def apply(scope)
      scope.where(age: range, dob_quality: [1, 2])
    end

    # there's no bucket in the spec to count individuals with missing dobs
    def self.all
      [
        new(label: 'Younger than 18', range: 0...18),
        new(range: 18..30),
        new(range: 31..50),
        new(label: '51 or Older', range: 51..),
      ]
    end
  end
end
