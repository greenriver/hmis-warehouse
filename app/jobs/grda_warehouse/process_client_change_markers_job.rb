###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Processes client records from the dirty processing queue
module GrdaWarehouse
  class ProcessClientChangeMarkersJob < BaseJob
    def self.enqueue_if_not_already_running
      perform_later if Delayed::Job.jobs_for_class(klass.sti_name).empty?
    end

    def perform(limit: 5_000, cursor_id: 0, wait_time: 5.minutes)
      instrument_as_maintenance_task do |run|
        with_lock do
          dirty_scope = ::GrdaWarehouse::ClientChangeMarker.dirty
          batch = dirty_scope.order(:client_id).limit(limit).where(client_id: cursor_id...)

          # could include other processing tasks here
          process_ce_eligibility(batch)

          # mark the as processed
          ::GrdaWarehouse::ClientChangeMarker.mark_processed(batch)

          # requeue job for the future with the next batch
          next_cursor_id = batch.any? ? (batch.map(&:client_id).max + 1) : 0
          ::GrdaWarehouse::ProcessClientChangeMarkersJob.
            set(wait: wait_time).
            perform_later(cursor_id: next_cursor_id)

          run.complete!
        end
      end
    end

    protected

    # run the hmis CE eligibility
    def process_ce_eligibility(matches)
      return if matches.empty?
      return unless ::HmisEnforcement.hmis_enabled?
      return unless ::Hmis::Ce.configuration.enabled?

      client_scope = ::GrdaWarehouse::Hud::Client.destination.where(id: matches.map(&:client_id))
      candidate_pool_ids = ::Hmis::Ce::Opportunity.active.pluck(:candidate_pool_id).compact.uniq
      candidate_pool_scope = ::Hmis::Ce::Match::CandidatePool.where(id: candidate_pool_ids)
      candidate_pool_scope.find_each do |pool|
        ::Hmis::Ce::Match::Engine.call(pool, client_scope)
      end
    end

    def with_lock(&block)
      lock_name = self.class.name.to_s
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
