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
      household_ids = scope.distinct.pluck(:report_household_id)
      scope.unscope(:select, :order, :limit, :offset).where(report_household_id: household_ids)
    end

    # Filters to households where ANY member has at least one of the specified values.
    # Loads records into memory for simplicity since datasets are small.
    def households_with_any_member_having(scope, field:, values:, type:)
      all_members = household_members(scope).to_a

      matching_household_ids = all_members.group_by(&:report_household_id).filter_map do |household_id, members|
        has_match = members.any? { |member| (member.public_send(field) & values.map(&:to_s)).any? }
        household_id if has_match
      end

      scope.where(report_household_id: matching_household_ids)
    end
  end
end
