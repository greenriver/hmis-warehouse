# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# all rows matching any filters
module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  IncludeFilter = Struct.new(:id, :label, :filters, keyword_init: true) do
    def apply(scope)
      filtered_scope = filters.map { |filter| filter.apply(scope) }.reduce { |a, b| a.or(b) }
      scope.where(id: filtered_scope.select(:id))
    end
  end
end
