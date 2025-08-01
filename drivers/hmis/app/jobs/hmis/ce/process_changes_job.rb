###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::ProcessChangesJob
#
# Continuously processes dirty CE (Coordinated Entry) clients and candidate pools to maintain
# up-to-date eligibility calculations. This job self-schedules to ensure  continuous processing
# while using advisory locks to prevent concurrent execution.
#
# See drivers/hmis/app/models/hmis/ce/README_FOR_CHANGE_MARKER.md
#
module Hmis::Ce
  class ProcessChangesJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # Enqueues the job only if no other instance is currently queued or running.
    # This prevents job queue buildup while ensuring the processing continues.
    #
    # @param args [Hash] Arguments to pass to perform_later
    def self.enqueue_if_not_already_running(...)
      perform_later(...) if Delayed::Job.jobs_for_class(name).empty?
    end

    # Processes batches of dirty clients and candidate pools for CE eligibility updates.
    #
    # @param next_pool_id [Integer] Starting pool ID for batch processing (pagination)
    # @param next_client_id [Integer] Starting client ID for batch processing (pagination)
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before scheduling next batch.
    #        If nil, job will not reschedule itself.
    # @param progress [Boolean] Whether to display progress bar (development aid)
    def perform(next_pool_id: nil, next_client_id: nil, wait_time: nil, progress: false)
      raise unless Hmis::Ce.configuration.enabled? && HmisEnforcement.hmis_enabled?

      next_pool_id ||= 0
      next_client_id ||= 0

      Rails.logger.info("Starting CE ProcessChangesJob with next_pool_id: #{next_pool_id}, next_client_id: #{next_client_id}")

      instrument_as_maintenance_task do |run|
        # ensure only one instance of this job runs simultaneously
        with_lock do
          @progress = progress
          Rails.logger.info("Acquired lock, starting change processing")
          reconcile_untracked_records

          # get a batch of dirty clients
          dirty_client_markers = Hmis::Ce::ChangeMarker.dirty.clients.batch(
            start_id: next_client_id,
            limit: 1_000,
          )
          # execute client query before pool processing. This ensures that if a new dirty client mark
          # appears while we are processing pools, the client won't be incorrectly marked as clean
          dirty_client_markers = dirty_client_markers.to_a
          Rails.logger.info("Found #{dirty_client_markers.count} dirty client markers to process")

          # load the dirty pools
          dirty_pool_markers = Hmis::Ce::ChangeMarker.dirty.pools.batch(
            start_id: next_pool_id,
            limit: 10,
          ).to_a
          Rails.logger.info("Found #{dirty_pool_markers.count} dirty pool markers to process")
          # process dirty pools
          next_pool_id = process_dirty_pools(dirty_pool_markers)
          Rails.logger.info("Completed processing dirty pools")

          # now process dirty clients, skipping the pools we just processed
          next_client_id = process_dirty_clients(
            dirty_client_markers,
            skip_pool_ids: dirty_pool_markers.map(&:trackable_id),
          )
          Rails.logger.info("Completed processing dirty clients")
          run.complete!

          schedule_next_batch(
            next_pool_id: next_pool_id,
            next_client_id: next_client_id,
            wait_time: wait_time,
          )
          Rails.logger.info("CE ProcessChangesJob batch completed successfully")
        end
      end
    end

    protected

    # Schedules the next batch of processing if wait_time is provided.
    #
    # @param next_pool_id [Integer] Starting pool ID for next batch
    # @param next_client_id [Integer] Starting client ID for next batch
    # @param wait_time [ActiveSupport::Duration, nil] Time to wait before next execution
    def schedule_next_batch(next_pool_id: 0, next_client_id: 0, wait_time: nil)
      return unless wait_time

      Rails.logger.info("Scheduling next batch with wait_time: #{wait_time}")
      self.class.set(wait: wait_time).perform_later(
        next_pool_id: next_pool_id,
        next_client_id: next_client_id,
        wait_time: wait_time,
      )
    end

    # Processes dirty candidate pools by running the match engine against all destination clients.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty pool markers to process
    # @return [Integer, nil] Next pool ID for pagination
    def process_dirty_pools(markers)
      return 0 if markers.empty?

      Rails.logger.info("Processing #{markers.count} dirty pools")
      # we expect processing an individual pool to be expensive; load one pool at a time mark it as clean
      # as soon as it's done
      markers.each do |marker|
        pool = ::Hmis::Ce::Match::CandidatePool.active.find_by(id: marker.trackable_id)
        next unless pool

        Hmis::Ce::Match::Engine.call(pool, progress: @progress)
        marker.mark_processed
      end

      markers.map(&:trackable_id).max + 1
    end

    # Processes dirty clients by running the match engine against active candidate pools.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty client markers to process
    # @param skip_pool_ids [Array<Integer>] Pool IDs to skip (already processed in this cycle)
    # @return [Integer, nil] Next client ID for pagination
    def process_dirty_clients(markers, skip_pool_ids:)
      return 0 if markers.empty?

      Rails.logger.info("Processing #{markers.count} dirty clients against active pools")
      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: markers.map(&:trackable_id))
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active.where.not(id: skip_pool_ids)

      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, clients: client_scope, progress: @progress)
      end

      Hmis::Ce::ChangeMarker.mark_processed(markers)
      markers.map(&:trackable_id).max + 1
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end

    private

    # Safeguard to ensure data integrity. This method finds and corrects active pools and
    # destination clients that should be tracked but are missing a change marker.
    #
    # While all new records should trigger the creation of a change marker, this reconciliation
    # ensures that any records that slip through (e.g., due to a new data import path) are not
    # ignored by the incremental processor.
    def reconcile_untracked_records
      Rails.logger.info("Starting reconciliation of untracked records")

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
      Rails.logger.info("Reconciled #{untracked_pools_count} untracked pools") if untracked_pools_count > 0

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
      Rails.logger.info("Reconciled #{untracked_clients_count} untracked clients") if untracked_clients_count > 0
    end
  end
end
