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
      return unless should_run? || force_run

      notifier = new.notifier
      message = 'Generating confidence for days homeless'
      Rails.logger.info message
      notifier&.ping message
      if should_start_a_new_batch? || force_create
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
          ::Confidence::DaysHomelessJob.new(client_ids: batch),
          queue: :long_running,
        )
      end
    end

    # only ever store one per census day.  We may hit a scenario where we get two consecutive days
    # but generally this should  happen once a week
    def self.calculate_queued_for_client client_id
      dates_homeless = GrdaWarehouse::Hud::Client.dates_homeless(client_id: client_id)
      census_dates = queued.where(resource_id: client_id).
        where(arel_table[:calculate_after].lteq(Date.current)).
        distinct.
        pluck(:census)
      # puts "Calculating for #{client_id}, dates: #{census_dates.inspect}"
      census_dates.each do |census|
        # get the next one to calculate
        dh = queued.where(resource_id: client_id, census: census).
          order(iteration: :asc).first
        dh.value = dates_homeless.select { |date| date <= dh.census }.count
        dh.calculated_on = Date.current
        if dh.iteration.positive?
          previous_iteration = find_by(
            resource_id: client_id,
            census: dh.census,
            iteration: dh.iteration - 1,
          )
          dh.change = begin
                        dh.value - previous_iteration.value
                      rescue StandardError
                        nil
                      end
        end
        dh.save
      end
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistoryEnrollment.entry.homeless.ongoing
    end
  end
end
