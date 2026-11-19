###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddLowerHouseholdIdIndexToEnrollment < ActiveRecord::Migration[8.1]
  def change
    # Staging and production build this index concurrently, outside the deploy, via the
    # :files_client_id_and_enrollment_household_id_indexes TaskQueue task
    # (GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes). Keep the definitions in sync.
    return unless Rails.env.local?

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
