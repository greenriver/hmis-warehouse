###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Confidence::ConfidenceJob is an abstract class to capture commonalities among various
# specific confidence jobs.

module Confidence
  class ConfidenceJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # Grab a batch of queued census calculations
    # and update at least one for each client.
    def initialize(client_ids:)
      @client_ids = client_ids
    end

    # A data monitoring model o be specified in the child class.
    private def dm_model
      raise NotImplementedError
    end

    # Each dm_model  must define a `batch_scope`. The Confidence::Base model creates
    # the batch that gets passed in here.
    private def counts_for_batch(batch)
      # This is where most of the work needs to be done in the specific confidence job.
      raise NotImplementedError
    end

    def perform
      # 1. get the first queued iteration for each client
      queued_for_batch = dm_model.queued.where(
        resource_id: @client_ids,
      ).order(:resource_id, iteration: :asc).distinct_on(:resource_id)

      unless queued_for_batch.any?
        dm_model.logger.warn { "#{self.class} found no queued requests. Nothing to do." }
        return
      end

      counts_for_batch(queued_for_batch)

      # The next 32 or so lines are solely about calculating the delta
      # We _could_ potentially just get that from queries when needed
      interesting_census_dates = queued_for_batch.map(&:census).uniq
      # Get the last iterations values by client_id and census date
      previous_values = {}
      dm_model.processed.where(
        resource_id: @client_ids,
        census: interesting_census_dates,
      ).order(
        :resource_id,
        :census,
        iteration: :desc, # most recent first
      ).distinct_on(
        :resource_id,
        :census,
      ).pluck(
        :resource_id, :census, :iteration, :value
      ).each do |resource_id, census, iteration, value|
        previous_values[[resource_id, census, iteration]] = value
      end

      queued_for_batch.each do |record|
        record.calculated_on = Date.current
        next unless record.iteration.positive?

        previous_key = [record.resource_id, record.census, record.iteration - 1]
        previous_value = previous_values[previous_key]
        if previous_value
          record.change = record.value - previous_value
        else
          dm_model.logger.warn { "#{self.class} missing #{previous_key.inspect}. Cannot calculate change" }
          record.change = nil
        end
      end

      # Bulk update the batch
      dm_model.import(
        queued_for_batch.map(&:attributes),
        on_duplicate_key_update: [:calculated_on, :value, :change],
      )
    end

    def enqueue(job, queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running))
    end

    def max_attempts
      2
    end
  end
end
