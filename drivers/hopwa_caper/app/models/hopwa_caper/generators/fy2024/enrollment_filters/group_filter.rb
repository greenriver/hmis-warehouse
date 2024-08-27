###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  GroupFilter = Struct.new(:label, :exclude_filters, keyword_init: true) do
    def apply(scope)
      exclude_scope = exclude_filters.reduce(scope) do |result, filter|
        filter.apply(result)
      end
      scope.where.not(id: exclude_scope.select(:id))
    end
  end
end
