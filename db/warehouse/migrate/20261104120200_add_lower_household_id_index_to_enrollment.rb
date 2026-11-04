###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Serves Hmis::Hud::Enrollment.matching_search_term's HouseholdID lookups:
#   LOWER("Enrollment"."HouseholdID") LIKE 'abc123%'
#   LOWER("Enrollment"."HouseholdID") = 'abc123...'
# text_pattern_ops lets LIKE prefix searches use the index under a non-C
# collation, and it still serves plain equality, so one index covers both. The
# predicate matches the paranoid default scope.
class AddLowerHouseholdIdIndexToEnrollment < ActiveRecord::Migration[8.1]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    # The build blocks writes to "Enrollment" (not reads) while it runs.
    safety_assured do
      add_index(
        :Enrollment,
        'lower("HouseholdID") text_pattern_ops',
        name: :idx_enrollment_on_lower_household_id_pattern,
        where: '"DateDeleted" IS NULL',
        if_not_exists: true,
      )
    end
  end
end
