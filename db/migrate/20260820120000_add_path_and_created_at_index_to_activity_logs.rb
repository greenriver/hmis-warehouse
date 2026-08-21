###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddPathAndCreatedAtIndexToActivityLogs < ActiveRecord::Migration[7.2]
  # activity_logs is a large, frequently-written-to table; a plain (transactional)
  # index build would hold a long-lived lock against it. This migration only adds
  # the index, so a failed concurrent build just leaves an invalid index to drop
  # and retry, without affecting any other migration.
  # rubocop:disable Migrations/DisableDdlTransaction
  disable_ddl_transaction!

  def change
    safety_assured do
      add_index :activity_logs, [:path, :created_at],
                name: 'index_activity_logs_on_path_and_created_at',
                opclass: { path: :varchar_pattern_ops },
                algorithm: :concurrently
    end
  end
  # rubocop:enable Migrations/DisableDdlTransaction
end
