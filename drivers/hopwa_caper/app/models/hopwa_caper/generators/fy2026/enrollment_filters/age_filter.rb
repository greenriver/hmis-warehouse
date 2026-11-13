###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  AgeFilter = Struct.new(:label, :range, keyword_init: true) do
    def label
      self[:label] || "#{range.begin}-#{range.end}"
    end

    def apply(scope)
      scope.where(age: range)
    end

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
