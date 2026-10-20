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
  # item_id can't be used instead: compose_activity seeds it from params[:id], so on nested routes
  # (/clients/<id>/files/<file_id>) it holds the dependent record's id, and log_client's `||=` keeps it.
  def change
    add_column :activity_logs, :client_id, :bigint
  end
end
