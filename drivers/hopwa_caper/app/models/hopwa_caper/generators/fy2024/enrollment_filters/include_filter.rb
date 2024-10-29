###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# all rows matching any filters
module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  IncludeFilter = Struct.new(:label, :filters, keyword_init: true) do
    def apply(scope)
      filtered_scope = filters.map { |filter| filter.apply(scope) }.reduce { |a, b| a.or(b) }
      scope.where(id: filtered_scope.select(:id))
    end
  end
end
