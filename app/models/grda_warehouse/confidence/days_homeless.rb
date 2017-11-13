module GrdaWarehouse::Confidence
  class DaysHomeless < Base
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    attr_accessor :notifier

    def initialize
      setup_notifier('Confidence Generator -- Days Homeless')
    end

    def self.iterations
      24
    end

    def self.iteration_length
      :weeks
    end

    def self.census_iterations
      1
    end

    def self.census_iteration_length
      :months
    end

    def self.census_day
      15
    end

    # Start a new batch once a month
    # This should only run once a week, so it should only catch once a month
    def self.should_start_a_new_batch?
      Date.today.day <= 7      
    end


    # only run on Saturdays
    def self.should_run?
      Date.today.day == 6
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
      queued.distinct.pluck(:client_id).each_slice(250) do |batch|
        Delayed::Job.enqueue(
          ::Confidence::DaysHomelessJob.new(client_ids: batch), 
          queue: :low_priority
        )
      end
    end

    def self.calculate_queued_for_client client_id
      dates_homeless = GrdaWarehouse::Hud::Client.dates_homeless(client_id: client_id)
      queued.where(client_id: client_id).each do |dh|
        dh.value = dates_homeless.select{|date| date <= dh.census}.count
        dh.calculated_on = Date.today
        if dh.iteration > 0
          previous_iteration = find_by(
            client_id: client_id, 
            census: dh.census,
            iteration: dh.iteration - 1
          )
          dh.change = dh.value - previous_iteration.value rescue nil
        end
        dh.save
      end
    end

    def self.update_delta_for_client client_id

    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistory.entry.homeless.ongoing
    end
  end
end