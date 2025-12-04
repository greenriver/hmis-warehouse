# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  # Provides helpers for filters that need to consider all household members while
  # respecting the original scope constraints (report instance, project filters, etc.).
  module HouseholdScopedFilter
    private

    def household_members(scope)
      HopwaCaper::Enrollment.
        from("#{HopwaCaper::Enrollment.table_name} household_members").
        joins("INNER JOIN (#{scoped_households(scope).to_sql}) scoped_households ON scoped_households.report_household_id = household_members.report_household_id")
    end

    def scoped_households(scope)
      scope.
        unscope(:select, :order, :limit, :offset).
        select(:report_household_id).
        distinct
    end

    # Filter to households where ANY member has at least one of the specified array values.
    # Returns a scope filtered to households matching the condition.
    def households_with_any_member_having(scope, field:, values:, type:)
      household_ids = household_members(scope).
        where(SqlHelper.array_overlap_condition(field: "household_members.#{field}", set: values, type: type)).
        select(:report_household_id).
        distinct
      scope.where(report_household_id: household_ids)
    end
  end
end
