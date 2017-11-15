# Record the number of source enrollments for all homeless clients
# on the day this is run, we don't have any way to look back to how many
# we had on a given day, so we'll just look for spikes
module GrdaWarehouse::Confidence
  class SourceEnrollments < Base
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, foreign_key: :resource_id

    attr_accessor :notifier

    def initialize
      setup_notifier('Confidence Generator -- Source Enrollments')
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
      message = "Generating confidence for source enrollments"
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
          ::Confidence::SourceEnrollmentsJob.new(client_ids: batch), 
          queue: :low_priority
        )
      end
    end

    def self.calculate_queued_for_client client_id
      source_enrollment_count = GrdaWarehouse::Hud::Client.where(id: client_id).
        joins(:source_enrollments).count
      queued.where(resource_id: client_id).each do |se|
        se.value = source_enrollment_count
        se.calculated_on = Date.today
        if previous = previous_census_date(client_id: client_id, source_enrollment: se)
          previous_iteration = find_by(
            resource_id: client_id,
            census: previous
          )
          se.change = se.value - previous_iteration.value rescue nil
        end
        se.save
      end
    end

    def self.previous_census_date client_id:, source_enrollment:
      where(resource_id: client_id).
        where(arel_table[:census].lt(source_enrollment.census)).
        maximum(:census)
    end

    def self.batch_scope
      GrdaWarehouse::ServiceHistory.entry.homeless.ongoing
    end
  end
end