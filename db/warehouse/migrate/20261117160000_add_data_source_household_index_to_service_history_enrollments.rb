###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HUD report household lookups join service history entries on data_source_id and household_id.
class AddDataSourceHouseholdIndexToServiceHistoryEnrollments < ActiveRecord::Migration[8.1]
  def change
    # Staging and production build this index concurrently, outside the deploy, via the
    # :service_history_enrollment_household_index TaskQueue task
    # (GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes). Keep the definitions in sync.
    return unless Rails.env.local?

    safety_assured do
      add_index(
        :service_history_enrollments,
        [:data_source_id, :household_id],
        name: :index_she_on_ds_household_id_entry,
        where: "record_type = 'entry'",
        if_not_exists: true,
      )
    end
  end
end
