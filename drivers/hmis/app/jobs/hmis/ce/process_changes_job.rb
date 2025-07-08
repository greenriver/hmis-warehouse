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
    def perform(next_pool_id: 0, next_client_id: 0, wait_time: nil, progress: false)
      raise unless Hmis::Ce.configuration.enabled? && HmisEnforcement.hmis_enabled?

      instrument_as_maintenance_task do |run|
        # ensure only one instance of this job runs simultaneously
        with_lock do
          @progress = progress
          reconcile_untracked_records

          # get a the batch of dirty clients
          dirty_client_markers = Hmis::Ce::ChangeMarker.dirty.clients.batch(
            start_id: next_client_id,
            limit: 1_000,
          )
          # execute client query before pool processing. This ensures that if a new dirty client mark
          # appears while we are processing pools, the client won't be incorrectly marked as clean
          dirty_client_markers = dirty_client_markers.to_a

          # load the dirty pools
          dirty_pool_markers = Hmis::Ce::ChangeMarker.dirty.pools.batch(
            start_id: next_pool_id,
            limit: 50,
          ).to_a
          # process dirty pools
          next_pool_id = process_dirty_pools(dirty_pool_markers)

          # now process dirty clients, skipping the pools we just processed
          next_client_id = process_dirty_clients(
            dirty_client_markers,
            skip_pool_ids: dirty_pool_markers.map(&:trackable_id),
          )
          run.complete!

          schedule_next_batch(
            next_pool_id: next_pool_id,
            next_client_id: next_client_id,
            wait_time: wait_time,
          )
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

      self.class.set(wait: wait_time).perform_later(
        next_pool_id: next_pool_id,
        next_client_id: next_client_id,
        wait_time: wait_time,
      )
    end

    # Processes dirty candidate pools by running the match engine against all destination clients.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty pool markers to process
    # @return [Integer, nil] Next pool ID for pagination, or nil if no markers processed
    def process_dirty_pools(markers)
      return nil if markers.empty?

      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active.where(id: markers.map(&:trackable_id))
      client_scope = ::GrdaWarehouse::Hud::Client.destination

      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, client_scope, progress: @progress)
      end

      Hmis::Ce::ChangeMarker.mark_processed(markers)
      markers.map(&:trackable_id).max + 1
    end

    # Processes dirty clients by running the match engine against active candidate pools.
    #
    # @param markers [Array<Hmis::Ce::ChangeMarker>] Dirty client markers to process
    # @param skip_pool_ids [Array<Integer>] Pool IDs to skip (already processed in this cycle)
    # @return [Integer, nil] Next client ID for pagination, or nil if no markers processed
    def process_dirty_clients(markers, skip_pool_ids:)
      return nil if markers.empty?

      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: markers.map(&:trackable_id))
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active.where.not(id: skip_pool_ids)

      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, client_scope, progress: @progress)
      end

      Hmis::Ce::ChangeMarker.mark_processed(markers)
      markers.map(&:trackable_id).max + 1
    end

    def log(message)
      @notifier&.ping("[#{self.class.name}] #{message}")
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end

    private

    # Safeguard to ensure data integrity: finds active pools and destination clients that should be
    # tracked but are missing a change marker. Ensures that all relevant records are eventually processed
    # by the CE engine.
    def reconcile_untracked_records
      # Find untracked active pools
      untracked_pools_scope = Hmis::Ce::Match::CandidatePool.active.
        left_outer_joins(:change_marker).
        where(hmis_ce_change_markers: { id: nil })

      untracked_pools_scope.in_batches do |relation|
        Hmis::Ce::ChangeMarker.upsert_or_bump_version('Hmis::Ce::Match::CandidatePool', trackable_ids: relation.pluck(:id))
      end

      # Find untracked destination clients
      untracked_clients_scope = GrdaWarehouse::Hud::Client.destination.
        left_outer_joins(:change_marker).
        where(hmis_ce_change_markers: { id: nil })
      untracked_clients_scope.in_batches do |relation|
        Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: relation.pluck(:id))
      end
    end
  end
end
