###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::ProcessChangesJob
# Processes dirty client and pools
#
module Hmis::Ce
  class ProcessChangesJob < BaseJob
    include NotifierConfig

    # lets cron kick off the job if not already running
    def self.enqueue_if_not_already_running(...)
      perform_later(...) if Delayed::Job.jobs_for_class(name).empty?
    end

    def perform(next_pool_id: 0, next_client_id: 0, wait_time: nil)
      raise unless Hmis::Ce.configuration.enabled? && HmisEnforcement.hmis_enabled?

      instrument_as_maintenance_task do |run|
        # ensure only one instance of this job runs simultaneously
        with_lock do
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
            limit: 100,
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

    def schedule_next_batch(next_pool_id: 0, next_client_id: 0, wait_time: nil)
      return unless wait_time

      self.class.set(wait: wait_time).perform_later(
        next_pool_id: next_pool_id,
        next_client_id: next_client_id,
        wait_time: wait_time,
      )
    end

    def process_dirty_pools(markers)
      return nil if markers.empty?

      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active.where(id: markers.map(&:trackable_id))
      client_scope = ::GrdaWarehouse::Hud::Client.destination

      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, client_scope)
      end

      Hmis::Ce::ChangeMarker.mark_processed(markers)
      markers.map(&:trackable_id).max + 1
    end

    def process_dirty_clients(markers, skip_pool_ids:)
      return nil if markers.empty?

      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: markers.map(&:trackable_id))
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.active.where.not(id: skip_pool_ids)

      candidate_pool_scope.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, client_scope)
      end

      Hmis::Ce::ChangeMarker.mark_processed(markers)
      markers.any? ? (markers.map(&:trackable_id).max + 1) : 0
    end

    def log(message)
      @notifier&.ping("[#{self.class.name}] #{message}")
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
