###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::ProcessClientsJob
#
# Processes dirty CE clients by running the match engine against active candidate pools.
# This job runs frequently to provide low-latency updates for client eligibility changes.
# Uses non-blocking per-pool advisory locks to coordinate with ProcessPoolsJob.
#
# See drivers/hmis/app/models/hmis/ce/README_FOR_CE_PROCESSING.md
#
module Hmis::Ce
  class ProcessClientsJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    # Enqueues the job only if no other instance is currently queued or running.
    # This prevents job queue buildup while ensuring the processing continues.
    #
    # @param args [Hash] Arguments to pass to perform_later
    def self.enqueue_if_not_already_running(...)
      perform_later(...) if Delayed::Job.jobs_for_class(name).empty?
    end

    # Processes batches of dirty clients for CE eligibility updates.
    #
    # @param next_client_id [Integer] Starting client ID for batch processing (pagination)
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before scheduling next batch.
    #        If nil, job will not reschedule itself.
    # @param progress [Boolean] Whether to display progress bar (development aid)
    def perform(next_client_id: nil, wait_time: nil, progress: false)
      raise 'CE configuration not enabled or HMIS enforcement disabled' unless Hmis::Ce.configuration.enabled? && HmisEnforcement.hmis_enabled?

      next_client_id ||= 0

      log_info("Starting with next_client_id: #{next_client_id}")

      instrument_as_maintenance_task do |run|
        # ensure only one instance of this job runs simultaneously
        with_lock do
          @progress = progress
          log_info('Acquired job lock, starting client processing')
          reconcile_untracked_clients

          # get a batch of dirty clients
          dirty_client_markers = Hmis::Ce::ChangeMarker.dirty.clients.batch(
            start_id: next_client_id,
            limit: 1_000,
          ).to_a
          log_info("Found #{dirty_client_markers.count} dirty client markers to process")
          reconcile_dangling_markers(dirty_client_markers)

          # process dirty clients against all available pools
          next_client_id = process_dirty_clients(dirty_client_markers)
          log_info('Completed processing dirty clients')
          run.complete!

          schedule_next_batch(
            next_client_id: next_client_id,
            wait_time: wait_time,
          )
          log_info('Batch completed successfully')
        end
      end
    end

    protected

    # Schedules the next batch of processing if wait_time is provided.
    #
    # @param next_client_id [Integer] Starting client ID for next batch
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before next execution
    def schedule_next_batch(next_client_id: 0, wait_time: nil)
      return unless wait_time

      log_info("Scheduling next batch with wait_time: #{wait_time}")
      self.class.set(wait: wait_time).perform_later(
        next_client_id: next_client_id,
        wait_time: wait_time,
      )
    end

    # Processes dirty clients by running the match engine against active candidate pools.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty client markers to process
    # @return [Integer, nil] Next client ID for pagination
    def process_dirty_clients(markers)
      return 0 if markers.empty?

      log_info("Processing #{markers.count} dirty clients against active pools")
      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: markers.map(&:trackable_id))
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active

      pools_processed = 0
      pools_skipped = 0

      candidate_pool_scope.find_each do |pool|
        # Attempt to acquire a non-blocking lock on this specific pool to see if it's busy.
        acquired_lock = pool.lock_for_processing(timeout_seconds: 5) do
          log_debug("Acquired pool lock for pool #{pool.id}, running match engine for clients")
          Hmis::Ce::Match::Engine.call(pool, clients: client_scope, progress: @progress)
          pools_processed += 1
        end

        unless acquired_lock
          log_debug("Pool #{pool.id} is busy (locked by ProcessPoolsJob), skipping")
          pools_skipped += 1
        end
      end

      log_info("Processed clients against #{pools_processed} pools, skipped #{pools_skipped} busy pools")

      # Only mark clients as processed if they were evaluated against all available pools.
      # If any pools were skipped, the clients will remain dirty to be reprocessed on the next run.
      if pools_skipped.zero?
        Hmis::Ce::ChangeMarker.mark_processed(markers)
        log_info("Marked #{markers.count} client markers as processed.")
      else
        log_info(
          "#{markers.count} client markers remain dirty because #{pools_skipped} pools were skipped.",
        )
      end

      # Paginate based on the client's ID (trackable_id) to process the next batch.
      markers.map(&:trackable_id).max + 1
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end

    private

    # Removes change markers for clients that no longer exist. This prevents buildup of
    # orphaned records
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] The batch of markers to check.
    #        This array is modified in-place to remove dangling markers.
    def reconcile_dangling_markers(markers)
      return if markers.empty?

      # Efficiently find which clients in this batch actually exist
      trackable_ids = markers.map(&:trackable_id)
      existing_client_ids = GrdaWarehouse::Hud::Client.destination.where(id: trackable_ids).pluck(:id).to_set

      # Partition markers into existing and dangling in a single pass
      existing_markers, dangling_markers = markers.partition { |marker| existing_client_ids.include?(marker.trackable_id) }

      return if dangling_markers.empty?

      log_info("Reconciling: found and deleting #{dangling_markers.count} dangling client markers.")

      # Use delete_all for better performance since we're cleaning up orphaned records
      # No need for callbacks or object instantiation
      Hmis::Ce::ChangeMarker.where(id: dangling_markers.map(&:id)).delete_all

      # Replace the original array with only existing markers
      markers.replace(existing_markers)
    end

    def log_info(message)
      Rails.logger.info("[ProcessClientsJob] #{message}")
    end

    def log_debug(message)
      Rails.logger.debug("[ProcessClientsJob] #{message}")
    end

    # Safeguard to ensure data integrity. This method finds and corrects destination
    # clients that should be tracked but are missing a change marker.
    #
    # While all new records should trigger the creation of a change marker, this reconciliation
    # ensures that any records that slip through (e.g., due to a new data import path) are not
    # ignored by the incremental processor.
    def reconcile_untracked_clients
      log_info('Starting reconciliation of untracked clients')

      # Find and mark untracked destination clients
      # Without this, an untracked client would not be matched against opportunities until a
      # candidate pool changes or the daily full refresh occurs.
      untracked_clients_scope = GrdaWarehouse::Hud::Client.destination.
        left_outer_joins(:change_marker).
        where(hmis_ce_change_markers: { id: nil })

      untracked_clients_count = 0
      untracked_clients_scope.in_batches do |relation|
        batch_ids = relation.pluck(:id)
        untracked_clients_count += batch_ids.count
        Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: batch_ids)
      end
      log_info("Reconciled #{untracked_clients_count} untracked clients") if untracked_clients_count > 0
    end
  end
end
