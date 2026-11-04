###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Client file lists and counts filter on files.client_id, which has no index.
class AddIndexToFilesOnClientId < ActiveRecord::Migration[8.1]
  def change
    # Omit `algorithm: :concurrently`, so the migration runs in one transaction.
    # This avoids needing disable_ddl_transaction! which we've had issues with in the past.
    # The build blocks writes to `files` (not reads) while it runs.
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
