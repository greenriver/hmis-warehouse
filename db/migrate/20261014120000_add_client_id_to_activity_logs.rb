###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddClientIdToActivityLogs < ActiveRecord::Migration[7.2]
  # Existing rows are backfilled, and the client_id index built, out of band by the
  # :activity_log_client_id TaskQueue task; activity_logs is too large and too busy to do either
  # inside a deploy's migration.
  def change
    add_column :activity_logs, :client_id, :bigint
  end
end
