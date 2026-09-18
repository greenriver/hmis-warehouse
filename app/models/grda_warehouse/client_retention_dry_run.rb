###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rehearses ClientRetentionJob without writing: same batching, same rollup, same inactivity
# test, returning counts and timings so the query can be sized against production data
# before the feature is turned on. Safe to run from a console at any time.
class GrdaWarehouse::ClientRetentionDryRun
  SAMPLE_SIZE = 20

  # @param global_years [Integer] the window to rehearse with; GrdaWarehouse::Config is not read
  # @param batch_size [Integer] destinations per rollup query, the job's size by default
  # @param limit [Integer, nil] stop after this many destinations, for a quick sample
  def initialize(global_years:, batch_size: ClientRetentionJob::BATCH_SIZE, limit: nil)
    @global_years = global_years
    @batch_size = batch_size
    @limit = limit
  end

  # @return [Hash] :destinations, :batches, :elapsed_seconds, :slowest_batch_seconds,
  #   :evaluated_by_basis, :would_mark_by_basis, :sample_destination_ids
  def run
    today = Date.current
    evaluated = Hash.new(0)
    would_mark = Hash.new(0)
    sample = []
    destinations = 0
    batches = 0
    slowest = 0.0
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    scope.in_batches(of: @batch_size) do |batch|
      ids = batch.pluck(:id)
      ids = ids.first(@limit - destinations) if @limit
      break if ids.empty?

      batch_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      rows = GrdaWarehouse::InactiveClient.rollup_activity(destination_ids: ids, global_years: @global_years)
      slowest = [slowest, Process.clock_gettime(Process::CLOCK_MONOTONIC) - batch_started].max

      destinations += ids.size
      batches += 1
      rows.each do |row|
        evaluated[row[:basis]] += 1
        next unless row[:last_activity_on] < today - row[:retention_years].years

        would_mark[row[:basis]] += 1
        sample << row[:destination_id] if sample.size < SAMPLE_SIZE
      end
      break if @limit && destinations >= @limit
    end

    {
      destinations: destinations,
      batches: batches,
      elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
      slowest_batch_seconds: slowest,
      evaluated_by_basis: evaluated,
      would_mark_by_basis: would_mark,
      sample_destination_ids: sample,
    }
  end

  # Planner output for one batch of the rollup, sized like the job's.
  # @return [String]
  def explain
    ids = scope.limit(@batch_size).pluck(:id)
    sql = GrdaWarehouse::InactiveClient.rollup_activity_sql(destination_ids: ids, global_years: @global_years, explain: true)
    GrdaWarehouseBase.connection.select_all(sql).rows.flatten.join("\n")
  end

  private def scope
    GrdaWarehouse::Hud::Client.destination
  end
end
