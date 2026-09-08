###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCreatedAtUserIdIndexToHmisActivityLogs < ActiveRecord::Migration[7.2]
  # hmis_activity_logs is written on every HMIS request; a transactional index build would hold a
  # long lock against it, and a failed concurrent build only leaves an invalid index to drop and retry.
  # rubocop:disable Migrations/DisableDdlTransaction
  disable_ddl_transaction!

  def change
    safety_assured do
      add_index(
        :hmis_activity_logs, [:created_at, :user_id],
        name: 'index_hmis_activity_logs_on_created_at_and_user_id',
        algorithm: :concurrently
      )
    end
  end
  # rubocop:enable Migrations/DisableDdlTransaction
end
