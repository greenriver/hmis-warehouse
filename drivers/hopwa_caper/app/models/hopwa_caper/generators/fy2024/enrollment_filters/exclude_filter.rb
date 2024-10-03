###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# all rows except those matching any filters
module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  ExcludeFilter = Struct.new(:label, :filters, keyword_init: true) do
    def apply(scope)
      # Combine filters using `or` to create a union of all filtered records
      filtered_scope = filters.map { |filter| filter.apply(scope) }.reduce { |a, b| a.or(b) }
      scope.where.not(id: filtered_scope.select(:id))
    end
  end
end
