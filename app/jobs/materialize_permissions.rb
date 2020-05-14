# A job the update a materialized of which users
# have access to which clients.
# At this point all it does is walk the existing scopes
# and output timing data
require 'ruby-progressbar'
require 'pp'
require 'benchmark'
class MaterializePermissions < BaseJob
  # WIP:
  def perform
    bar = ProgressBar.create(starting_at: 0, total: nil, format: '%c - %R')
    reduce_logging do
      bm = Benchmark.measure do
        User.find_each do |user|
          GrdaWarehouse::Hud::Client.destination.searchable_by(user).pluck(:id).map do |client_id|
            bar.increment
            JSON.generate(user_id: user.id, client_id: client_id, viewable: true)
          end
        end
      end
      pp bar.to_h.slice('elapsed_time_in_seconds', 'progress')
      pp bm.to_s
    end
    nil
  end

  private def reduce_logging
    User.logger.silence(Logger::INFO) do
      GrdaWarehouse::Hud::Client.logger.silence(Logger::INFO) do
        yield
      end
    end
  end
end
