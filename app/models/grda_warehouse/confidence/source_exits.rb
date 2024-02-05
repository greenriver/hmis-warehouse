###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Record the number of source exits for all homeless clients
# on the day this is run, we don't have any way to look back to how many
# we had on a given day, so we'll just look for spikes
module GrdaWarehouse::Confidence
  class SourceExits < Base
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :resource_id

    attr_accessor :notifier
    after_initialize :add_notifier

    def add_notifier
      setup_notifier('Confidence Generator -- Source Exits')
    end

    def self.collection_dates_for_client client_id
      [{
        census: Date.current,
        calculate_after: Date.yesterday,
        iteration: 0,
        of_iterations: 1,
        resource_id: client_id,
        type: name,
      }]
    end

    def self.queue_batch force_run: false, force_create: false
      return unless force_run || should_run?

      notifier = new.notifier
      message = 'Generating confidence for source exits'
      Rails.logger.info message
      notifier&.ping message
      if force_create || should_start_a_new_batch?
        message = 'Setting up a new batch...'
        Rails.logger.info message
        notifier&.ping message
        create_batch!
        message = '... batch setup complete'
        Rails.logger.info message
        notifier&.ping message
      end
      queued.distinct.pluck(:resource_id).each_slice(250) do |batch|
        Delayed::Job.enqueue(
          ::Confidence::SourceExitsJob.new(client_ids: batch),
          queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running),
          priority: 10,
        )
      end
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistoryEnrollment.entry.homeless.ongoing
    end
  end
end
