###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Confidence
  class DaysHomeless < Base
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :resource_id

    attr_accessor :notifier
    after_initialize :add_notifier

    def add_notifier
      setup_notifier('Confidence Generator -- Days Homeless')
    end

    def self.queue_batch force_run: false, force_create: false
      return unless force_run || should_run?

      notifier = new.notifier
      message = 'Generating confidence for days homeless'
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
      # 250 keeps the queue full but not overfull
      queued.distinct.pluck(:resource_id).each_slice(250) do |batch|
        Delayed::Job.enqueue(
          ::Confidence::DaysHomelessJob.new(client_ids: batch),
          queue: :long_running,
          priority: 10,
        )
      end
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistoryEnrollment.entry.homeless.ongoing
    end
  end
end
