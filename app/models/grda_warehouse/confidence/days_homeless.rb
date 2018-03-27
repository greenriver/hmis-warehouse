module GrdaWarehouse::Confidence
  class DaysHomeless < Base
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, foreign_key: :resource_id

    attr_accessor :notifier

    def initialize
      setup_notifier('Confidence Generator -- Days Homeless')
    end

    def self.queue_batch force_run: false, force_create: false
      return unless should_run? || force_run
      notifier = self.new.notifier
      message = "Generating confidence for days homeless"
      Rails.logger.info message
      notifier.ping message if notifier
      if should_start_a_new_batch? || force_create
        message = "Setting up a new batch..."
        Rails.logger.info message
        notifier.ping message if notifier
        create_batch!()
        message = "... batch setup complete"
        Rails.logger.info message
        notifier.ping message if notifier
      end
      queued.distinct.pluck(:resource_id).each_slice(250) do |batch|
        Delayed::Job.enqueue(
          ::Confidence::DaysHomelessJob.new(client_ids: batch), 
          queue: :low_priority
        )
      end
    end

    # only ever store one per census day.  We may hit a scenario where we get two consecutive days
    # but generally this should  happen once a week
    def self.calculate_queued_for_client client_id
      dates_homeless = GrdaWarehouse::Hud::Client.dates_homeless(client_id: client_id)
      census_dates = queued.where(resource_id: client_id).
        where(arel_table[:calculate_after].lteq(Date.today)).
        distinct.
        pluck(:census)
      # puts "Calculating for #{client_id}, dates: #{census_dates.inspect}"
      census_dates.each do |census|
        # get the next one to calculate
        dh = queued.where(resource_id: client_id, census: census).
          order(iteration: :asc).first
        dh.value = dates_homeless.select{|date| date <= dh.census}.count
        dh.calculated_on = Date.today
        if dh.iteration > 0
          previous_iteration = find_by(
            resource_id: client_id, 
            census: dh.census,
            iteration: dh.iteration - 1
          )
          dh.change = dh.value - previous_iteration.value rescue nil
        end
        dh.save
      end
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistoryEnrollment.entry.homeless.ongoing
    end
  end
end