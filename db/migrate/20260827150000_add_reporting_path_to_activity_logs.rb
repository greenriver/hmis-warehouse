###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddReportingPathToActivityLogs < ActiveRecord::Migration[7.2]
  # rubocop:disable Migrations/DisableDdlTransaction
  disable_ddl_transaction!

  # `path` is an unmodified audit trail elsewhere and can't be bounded, so report-usage matching
  # instead uses this always-short mirror; see ActivityLog#reporting_path. Also drops the index
  # db/migrate/20260820120000_add_path_and_created_at_index_to_activity_logs.rb would have built
  # directly on `path`, for installations where it already ran before that became a no-op.
  #
  # Existing rows are backfilled out of band via TaskQueue (see
  # TaskQueue.register_tasks' :backfill_activity_log_reporting_path) rather than here, so this
  # migration stays fast regardless of table size; new rows get reporting_path immediately via
  # ActivityLog's before_save callback.
  def up
    safety_assured do
      remove_index :activity_logs, name: 'index_activity_logs_on_path_and_created_at', algorithm: :concurrently, if_exists: true
    end

    add_column :activity_logs, :reporting_path, :string
  end

  def down
    remove_column :activity_logs, :reporting_path
  end
  # rubocop:enable Migrations/DisableDdlTransaction
end
