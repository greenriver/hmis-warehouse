###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Runs the warehouse sync pipeline after a simulation run.
  #
  # Client linking and service history processing run synchronously.
  # The materialized view refresh and cached count updates are deferred to
  # RefreshWarehouseViewsJob so the rake task returns promptly; data appears
  # in reports once that job completes (eventual consistency).
  #
  # Note: IdentifyDuplicates and batch_process_unprocessed! are system-wide
  # operations — they process all unlinked clients and unprocessed enrollments,
  # not just those belonging to the simulation data source(s). On a server used
  # exclusively for simulation this is fine; on a staging server with real
  # imported data, each simulation run will re-run deduplication and service
  # history for all data sources. The view refresh (refresh_views) IS scoped
  # to the simulation destination clients via destination_ids.
  #
  # Usage:
  #   batch_start = Time.current
  #   # ... run engine ticks ...
  #   HmisSimulation::WarehouseSyncer.new(data_source_ids: [38]).call(updated_since: batch_start)
  class WarehouseSyncer
    def initialize(data_source_ids:)
      @data_source_ids = Array(data_source_ids).map(&:to_i)
    end

    def call(updated_since: nil)
      timed('link_clients') { link_clients }
      timed('process_service_history') { process_service_history }
      timed('refresh_views') { refresh_views(updated_since: updated_since) }
    end

    private

    def link_clients
      timed('  IdentifyDuplicates#run!') { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }
      timed('  IdentifyDuplicates#match_existing!') { GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing! }
    end

    def process_service_history
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!
    end

    def refresh_views(updated_since:)
      ids = destination_ids(updated_since: updated_since)
      HmisSimulation::RefreshWarehouseViewsJob.perform_later(destination_ids: ids)
    end

    def timed(label)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      Rails.logger.info(format('[HmisSimulation] %s: %.1fs', label, elapsed))
      $stdout.puts(format('  [sync] %s: %.1fs', label, elapsed))
    end

    # Returns destination client IDs for source clients that had enrollment
    # activity since updated_since. Falls back to all source clients in the
    # data source when updated_since is nil.
    # Note, the net is slightly wider than it needs to be, any client with the PersonalID in any of the data sources
    # instead of a set of PersonalIDs in their known data sources.
    def destination_ids(updated_since:)
      source_ids = if updated_since
        personal_ids = Hmis::Hud::Enrollment.
          where(data_source_id: @data_source_ids).
          where(DateCreated: updated_since..).
          pluck(:PersonalID).
          uniq
        Hmis::Hud::Client.
          where(data_source_id: @data_source_ids, PersonalID: personal_ids).
          pluck(:id)
      else
        Hmis::Hud::Client.where(data_source_id: @data_source_ids).pluck(:id)
      end
      GrdaWarehouse::WarehouseClient.where(source_id: source_ids).pluck(:destination_id)
    end
  end
end
