###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Client file lists and counts filter on files.client_id, which has no index.
class AddIndexToFilesOnClientId < ActiveRecord::Migration[8.1]
  def change
    # Staging and production build this index concurrently, outside the deploy, via the
    # :files_client_id_and_enrollment_household_id_indexes TaskQueue task
    # (GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes). Keep the definitions in sync.
    return unless Rails.env.local?

    safety_assured do
      add_index(
        :files,
        :client_id,
        name: :index_files_on_client_id,
        if_not_exists: true,
      )
    end
  end
end
