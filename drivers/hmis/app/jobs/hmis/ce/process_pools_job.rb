###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::ProcessPoolsJob
#
# Processes dirty CE candidate pools by running the match engine against all destination clients.
# It may re-enqueue itself if more dirty pools are found after processing a batch or after an
# early exit. Uses pool-level advisory locks to coordinate with ProcessClientsJob.
#
# See drivers/hmis/app/models/hmis/ce/README_FOR_CE_PROCESSING.md
#
module Hmis::Ce
  class ProcessPoolsJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # Enqueues the job only if no other instance is currently queued or running.
    # This prevents job queue buildup while ensuring the processing continues.
    #
    # @param args [Hash] Arguments to pass to perform_later
    def self.enqueue_if_not_already_running(...)
      perform_later(...) if Delayed::Job.jobs_for_class(name).empty?
    end

    # Processes batches of dirty candidate pools for CE eligibility updates.
    #
    # @param next_pool_id [Integer] Starting pool ID for batch processing (pagination)
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before scheduling next batch.
    #        If nil, job will not reschedule itself.
    # @param progress [Boolean] Whether to display progress bar (development aid)
    # @param batch_size [Integer] Number of pools to process in each batch
    def perform(next_pool_id: nil, wait_time: nil, progress: false, batch_size: 10)
      raise 'CE configuration not enabled or HMIS enforcement disabled' unless Hmis::Ce.configuration.enabled? && HmisEnforcement.hmis_enabled?

      next_pool_id ||= 0

      log_info("Starting with next_pool_id: #{next_pool_id}")

      instrument_as_maintenance_task do |run|
        # ensure only one instance of this job runs simultaneously
        with_lock do
          @progress = progress
          log_info('Acquired job lock, starting pool processing')
          reconcile_untracked_pools

          # get a batch of dirty pools
          dirty_pool_markers = Hmis::Ce::ChangeMarker.dirty.pools.batch_by_trackable_id(
            start_id: next_pool_id,
            limit: batch_size,
          ).to_a
          log_info("Found #{dirty_pool_markers.count} dirty pool markers to process")

          # process dirty pools
          next_pool_id = process_dirty_pools(dirty_pool_markers)
          log_info('Completed processing dirty pools')
          run.complete!

          if Hmis::Ce::ChangeMarker.dirty.pools.exists?
            schedule_next_batch(
              next_pool_id: next_pool_id,
              wait_time: wait_time,
              batch_size: batch_size,
            )
          end
          log_info('Batch completed successfully')
        end
      end
    end

    protected

    # Schedules the next batch of processing if wait_time is provided.
    #
    # @param next_pool_id [Integer] Starting pool ID for next batch
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before next execution
    # @param batch_size [Integer] Number of pools to process in next batch
    def schedule_next_batch(next_pool_id: 0, wait_time: nil, batch_size: 10)
      return unless wait_time

      log_info("Scheduling next batch with wait_time: #{wait_time}")
      self.class.set(wait: wait_time).perform_later(
        next_pool_id: next_pool_id,
        wait_time: wait_time,
        batch_size: batch_size,
      )
    end

    # Processes dirty candidate pools by running the match engine against all destination clients.
    # Uses per-pool advisory locks to coordinate with ProcessClientsJob.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty pool markers to process
    # @return [Integer, nil] Next pool ID for pagination
    def process_dirty_pools(markers)
      return 0 if markers.empty?

      log_info("Processing up to #{markers.count} dirty pools")

      # Paginate from the ID of the last pool we attempted to process in this batch.
      max_processed_trackable_id = nil

      markers.each do |marker|
        max_processed_trackable_id = [marker.trackable_id, max_processed_trackable_id].compact.max
        pool = ::Hmis::Ce::Match::CandidatePool.find_by(id: marker.trackable_id)
        unless pool&.active?
          # skip processing inactive pools and remove dangling markers
          pool ? marker.mark_processed : marker.destroy!
          next
        end

        # Acquire a blocking lock on this specific pool to prevent other jobs from processing it.
        acquired_lock = false
        pool.lock_for_processing(timeout_seconds: 60) do
          log_info("Acquired pool lock for pool #{pool.id}, running match engine")
          Hmis::Ce::Match::Engine.call(pool, progress: @progress)
          marker.mark_processed
          log_info("Completed processing pool #{pool.id}")
          acquired_lock = true
        end

        log_warning("Failed to acquire lock for pool #{pool.id} within timeout") unless acquired_lock

        # YIELDING LOGIC: If clients are dirty, exit to let the client job run.
        if Hmis::Ce::ChangeMarker.dirty.clients.exists?
          log_info('Dirty clients detected. Yielding to client processor.')
          break
        end
      end

      max_processed_trackable_id ? max_processed_trackable_id + 1 : 0
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end

    private

    def log_info(message)
      Rails.logger.info("[ProcessPoolsJob] #{message}")
    end

    def log_warning(message)
      Rails.logger.warn("[ProcessPoolsJob] #{message}")
    end

    # Safeguard to ensure data integrity. This method finds and corrects active pools
    # that should be tracked but are missing a change marker.
    #
    # While all new records should trigger the creation of a change marker, this reconciliation
    # ensures that any records that slip through (e.g., due to a new data import path) are not
    # ignored by the incremental processor.
    def reconcile_untracked_pools
      log_info('Starting reconciliation of untracked pools')

      # Find and mark untracked active pools
      untracked_pools_scope = Hmis::Ce::Match::CandidatePool.active.
        left_outer_joins(:change_marker).
        where(hmis_ce_change_markers: { id: nil })

      untracked_pools_count = 0
      untracked_pools_scope.in_batches do |relation|
        batch_ids = relation.pluck(:id)
        untracked_pools_count += batch_ids.count
        Hmis::Ce::ChangeMarker.upsert_or_bump_version('Hmis::Ce::Match::CandidatePool', trackable_ids: batch_ids)
      end
      log_info("Reconciled #{untracked_pools_count} untracked pools") if untracked_pools_count > 0
    end
  end
end
