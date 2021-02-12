###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A job the update a materialized of which users
# have access to which clients.
# At this point all it does is walk the existing scopes
# and output timing data

require 'pp'
require 'benchmark'

class MaterializePermissions < BaseJob
  COLS = ['user_id', 'client_id', 'viewable'].freeze

  def perform
    # WIP:
    # TODO: figure out how to handle other Client scopes...
    # TODO: what about (soft) deletes of both users and clients
    # TODO: do we add FK to the UserClientPermission model (which will slow things down a lot)
    # TODO: do we keep "deleted_at" records to provide audit history?

    insert_batch_size = 20_000
    reduce_logging do
      wh_db_exec("TRUNCATE TABLE #{GrdaWarehouse::UserClientPermission.quoted_table_name}")
      batch = []
      bm = Benchmark.measure do
        User.find_each do |user|
          GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id).map do |client_id|
            batch << [user.id, client_id, true] # see COLS
            if batch.size >= insert_batch_size
              process_batch(batch)
              batch.clear
            end
          end
        end
        process_batch(batch)
      end
      wh_db_exec("ANALYZE VERBOSE #{GrdaWarehouse::UserClientPermission.quoted_table_name}")
      puts "Benchmark.measure: #{bm}"
    end
    nil
  end

  private def process_batch(rows)
    # TODO: check for failed rows...
    GrdaWarehouse::UserClientPermission.import(COLS, rows, validate: false)
  end

  private def wh_db
    GrdaWarehouseBase.connection
  end

  private def wh_db_exec(sql)
    wh_db.execute(sql)
  end

  private def reduce_logging
    User.logger.silence(Logger::INFO) do
      GrdaWarehouse::Hud::Client.logger.silence(Logger::INFO) do
        yield
      end
    end
  end
end
