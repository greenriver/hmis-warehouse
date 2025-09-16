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
    include MaintenanceTaskInstrumentation

    def self.perform
      new.perform
    end

    def perform
      instrument_as_maintenance_task do |run|
        with_lock do
          GrdaWarehouseBase.transaction do
            sync_app_users
            # TODO: #7600 - delete breaks for some reason
            # prune_removed_users
            run.complete!
          end
        end
      end
    end

    protected

    def sync_app_users(batch_size: 500)
      User.with_deleted.preload(:agency).find_in_batches(batch_size: batch_size) do |batch|
        values_sql = batch.map do |user|
          sanitize_sql_for_insert(user)
        end.join(",\n")

        sql = <<~SQL
          INSERT INTO analytics.app_users (id, first_name, last_name, email, agency_name)
          VALUES
          #{values_sql}
          ON CONFLICT (id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            agency_name = EXCLUDED.agency_name
        SQL
        connection.execute(sql)
      end
    end

    def prune_removed_users
      current_user_ids = User.with_deleted.pluck(:id).map do |id|
        connection.quote(id)
      end

      if current_user_ids.any?
        id_list = current_user_ids.join(',')
        connection.execute(<<~SQL)
          DELETE FROM analytics.app_users
          WHERE id NOT IN (#{id_list})
        SQL
      else
        connection.execute('TRUNCATE TABLE analytics.app_users')
      end
    end

    def connection
      GrdaWarehouseBase.connection
    end

    def sanitize_sql_for_insert(user)
      ActiveRecord::Base.sanitize_sql_array(
        [
          '(?, ?, ?, ?, ?)',
          user.id,
          user.first_name,
          user.last_name,
          user.email,
          user.agency&.name,
        ],
      )
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
