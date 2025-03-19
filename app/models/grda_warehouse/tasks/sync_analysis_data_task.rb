# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Sync data from the app db into the warehouse analysis data for export. It's necessary to pul
# the data down and re-insert due to data boundary
#
# * This task can be removed if/when we unify the app and warehouse databases
# * An alternative to this periodic sync would be a foreign data wrapper
#
module GrdaWarehouse::Tasks
  class SyncAnalysisDataTask
    def self.perform(...)
      new.perform(...)
    end

    def perform
      with_lock do
        sync_app_users
      end
    end

    protected

    def sync_app_users(batch_size: 500)
      User.find_in_batches(batch_size: batch_size) do |batch|
        values_sql = batch.map do |user|
          sanitize_sql_for_insert(user)
        end.join(",\n")

        sql = <<~SQL
          INSERT INTO analytics.app_users (id, first_name, last_name, email)
          VALUES
          #{values_sql}
          ON CONFLICT (id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email
        SQL
        connection.execute(sql)
      end
    end

    def connection
      GrdaWarehouseBase.connection
    end

    def sanitize_sql_for_insert(user)
      ActiveRecord::Base.send(
        :sanitize_sql_array, [
          '(?, ?, ?, ?)',
          user.id,
          user.first_name,
          user.last_name,
          user.email,
        ]
      )
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
