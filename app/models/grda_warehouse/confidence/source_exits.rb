# Record the number of source exits for all homeless clients
# on the day this is run, we don't have any way to look back to how many
# we had on a given day, so we'll just look for spikes
module GrdaWarehouse::Confidence
  class SourceExits < Base
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, foreign_key: :resource_id

    attr_accessor :notifier

    def initialize
      setup_notifier('Confidence Generator -- Source Exits')
    end


    def self.collection_dates_for_client client_id
      [{
        census: Date.today,
        calculate_after: Date.yesterday,
        iteration: 0,
        of_iterations: 1,
        resource_id: client_id,
        type: name,
      }]    
    end

    def self.queue_batch force_run: false, force_create: false
      return unless should_run? || force_run
      notifier = self.new.notifier
      message = "Generating confidence for source exits"
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
          ::Confidence::SourceExitsJob.new(client_ids: batch), 
          queue: :low_priority
        )
      end
    end

    def self.calculate_queued_for_client client_id
      source_exit_count = GrdaWarehouse::Hud::Client.where(id: client_id).
        joins(:source_exits).count
      se = queued.where(resource_id: client_id).first
      se.value = source_exit_count
      se.calculated_on = Date.today
      if previous = previous_census_date(client_id: client_id, source_exit: se)
        previous_iteration = find_by(
          resource_id: client_id,
          census: previous
        )
        se.change = se.value - previous_iteration.value rescue nil
      end
      se.save
    end

    def self.previous_census_date client_id:, source_exit:
      where(resource_id: client_id).
        where(arel_table[:census].lt(source_exit.census)).
        maximum(:census)
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistory.entry.homeless.ongoing
    end
  end
end