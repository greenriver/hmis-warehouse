###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Processes dirty client records
# This is an "incremental update" job. It runs frequently on a batch of recently changed clients. It's designed for low latency
# If it fails to process a batch, it stops processing and reschedules the itself to re-process the same batch of client changes later
module GrdaWarehouse
  class ProcessClientChangeMarkersJob < BaseJob
    def self.enqueue_if_not_already_running(...)
      perform_later(...) if Delayed::Job.jobs_for_class(name).empty?
    end

    def perform(limit: 5_000, cursor_id: 0, wait_time: nil)
      instrument_as_maintenance_task do |run|
        with_lock do
          dirty_scope = ::GrdaWarehouse::ClientChangeMarker.dirty
          batch = dirty_scope.order(:client_id).limit(limit).where(client_id: cursor_id...)

          catch(:failure) do
            # could include other processing tasks here. Client may be processed multiple times so tasks should be idempotent
            process_ce_eligibility(batch)
          end

          if failure
            # we couldn't complete all the needed processing, try again
            Rails.logger.error "#{self.class.name}: #{failure}"
            schedule_next_batch(cursor_id: cursor_id, wait_time: wait_time)
          else
            # we completed the batch, mark the as processed and schedule the next batch
            ::GrdaWarehouse::ClientChangeMarker.mark_processed(batch)
            next_cursor_id = batch.any? ? (batch.map(&:client_id).max + 1) : 0
            schedule_next_batch(cursor_id: next_cursor_id, wait_time: wait_time)
          end

          run.complete!
        end
      end
    end

    protected

    # schedule job for the next batch
    def schedule_next_batch(cursor_id: cursor_id, wait_time: wait_time)
      return unless wait_time

      ::GrdaWarehouse::ProcessClientChangeMarkersJob.
        set(wait: wait_time).
        perform_later(cursor_id: cursor_id, wait_time: wait_time)
    end

    # run the hmis CE eligibility
    def process_ce_eligibility(markers)
      return if markers.empty?
      return unless ::HmisEnforcement.hmis_enabled?
      return unless ::Hmis::Ce.configuration.enabled?

      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: markers.map(&:client_id))
      candidate_pool_ids = ::Hmis::Ce::Opportunity.active.pluck(:candidate_pool_id).compact.uniq
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)
      candidate_pool_scope.find_each do |pool|
        completed = Hmis::Ce::Match::Engine.call(pool, client_scope)
        throw(:failure, "Failed acquire lock for CE candidate pool #{pool.id}") unless completed
      end
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
