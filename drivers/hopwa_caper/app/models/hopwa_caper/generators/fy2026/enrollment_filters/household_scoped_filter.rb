# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  # Helpers for filtering households based on attributes across all household members.
  # All methods preserve the original scope's constraints (report instance, date ranges, project filters).
  module HouseholdScopedFilter
    private

    # Returns all members of households present in the scope, preserving all scope constraints.
    # Example: if scope is "TBRA enrollments Jan-Dec 2024", returns all household members
    # who are also in TBRA during Jan-Dec 2024.
    def household_members(scope)
      scoped = scope.unscope(:select, :order, :limit, :offset)
      household_ids = scoped.select(:report_household_id).distinct
      scoped.where(report_household_id: household_ids)
    end

    # Filters to households where ANY member has at least one of the specified values.
    # Uses SQL overlaps to keep filtering in the database.
    def households_with_any_member_having(scope, field:, values:, type: nil)
      members = household_members(scope)
      household_ids = members.
        where.overlaps(field.to_sym => values.map(&:to_s)).
        select(:report_household_id).
        distinct

      scope.where(report_household_id: household_ids)
    end

    # Filters to households where NO members have values in the specified field.
    def households_with_no_member_having(scope, field:)
      members = household_members(scope)
      households_with_values = members.where.not(field.to_sym => [])

      empty_household_ids = members.
        select(:report_household_id).
        distinct.
        where.not(report_household_id: households_with_values.select(:report_household_id))

      scope.where(report_household_id: empty_household_ids)
    end
  end
end
