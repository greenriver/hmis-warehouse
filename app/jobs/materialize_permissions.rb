# A job the update a materialized of which users
# have access to which clients.
# At this point all it does is walk the existing scopes
# and output timing data

require 'ruby-progressbar'
require 'pp'
require 'benchmark'

class MaterializePermissions < BaseJob
  COLS = ['user_id', 'client_id', 'viewable'].freeze

  # WIP:
  def perform
    bar = ProgressBar.create(starting_at: 0, total: nil, format: '%c - %R')
    insert_batch_size = 1000
    reduce_logging do
      wh_db_exec("TRUNCATE TABLE #{GrdaWarehouse::UserClientPermission.quoted_table_name}")
      batch = []
      bm = Benchmark.measure do
        User.find_each do |user|
          GrdaWarehouse::Hud::Client.viewable_by(user).pluck(:id).map do |client_id|
            bar.increment
            batch << [user.id, client_id, true] # see COLS
          end
        end
        if batch.size >= insert_batch_size
          process_batch(batch)
          batch.clear
        end
      end
      wh_db_exec("ANALYZE VERBOSE #{GrdaWarehouse::UserClientPermission.quoted_table_name}")
      puts "Benchmark.measure: #{bm}"
      pp(
        elapsed_time_in_seconds: bar.to_h['elapsed_time_in_seconds'],
        rows_processed: bar.to_h['progress'],
      )
    end
    nil
  end

  private def process_batch(rows)
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
