###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Tasks
  class SanityCheckServiceHistory
    require 'ruby-progressbar'
    include ArelHelper
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config
    MAX_ATTEMPTS = 3 # We'll check anything a few times, but don't run forever
    CACHE_KEY = 'sanity_check_service_history'

    def initialize(sample_size = 10, client_ids = [])
      @sample_size = sample_size
      @client_ids = client_ids
      setup_notifier('Sanity Checker')
      @logger = Rails.logger
      @dirty = false
      if @client_ids.any?
        @sample_size = @client_ids.size
      end
      @batch_size = 1000
    end

    # Pick a sample of destination clients and compare the number of entry and exit records
    # they have in their source data to the number they have in their service history
    def run!
      logger.info "Sanity checking #{@sample_size} random clients..."
      choose_sample()
      # load_personal_ids()
      # Load all of the data in batches, sometimes the massive queries are slow
      @destinations.keys.each_slice(@batch_size) do |batch|
        load_service_history_enrollments(batch)
        load_service_history_exits(batch)
        load_source_enrollments(batch)
        load_source_exits(batch)
        # load_service_counts(batch)
        # load_source_service_counts(batch)
      end
      sanity_check()
      logger.info "...sanity check complete"
      @dirty
    end

    def sanity_check
      messages = []
      @destinations.each do |id, counts|
        if counts[:service_history].except(:service) != counts[:source].except(:service)
          msg = "```client: #{id} \n#{counts.except(:source_personal_ids).inspect}```\n"
          logger.warn msg
          messages << msg
          client_source.find(id).invalidate_service_history
          add_attempt(id)
        else
        end
      end
      update_attempts()
      if messages.any?
        @dirty = true
        rebuilding_message = "Rebuilding service history for #{messages.size} invalidated clients."
        if send_notifications
          msg = "Hey, the service history counts don't match for the following #{messages.size} client(s).  Service histories have been invalidated.\n"
          msg += messages.join("\n")
          msg += "\n\n#{rebuilding_message}"
          @notifier.ping msg
        end
        logger.info rebuilding_message
        GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
      end
    end

    def attempts
      @attempts ||= Rails.cache.fetch(CACHE_KEY, expires_in: 12.hours) do
        Hash.new(0)
      end
    end

    def add_attempt id
      attempts[id] += 1
    end

    def update_attempts
      # Rails.logger.debug('Saving Attempts')
      # Rails.logger.debug(attempts.inspect)
      Rails.cache.write(CACHE_KEY, attempts)
    end

    def max_attempts_reached id
      attempts[id] >= MAX_ATTEMPTS
    end

    def choose_sample
      if @client_ids.any?
        destinations = @client_ids
      else
        destinations = clients_processed_source.random.limit(@sample_size).pluck(:client_id)
      end
      # prevent infinite runs
      destinations.reject! do |id|
        max_attempts_reached(id)
      end
      @destinations = destinations.map do |m|
        [m, {
          service_history: {
            enrollments: 0,
            exits: 0,
          },
          source: {
            enrollments: 0,
            exits: 0,
          },
          source_personal_ids: []
        }]
      end.to_h
    end

    def load_personal_ids
      # This is brittle, if active record decides to change the name of the joined table, it won't work
      source_client_table = Arel::Table.new 'source_clients_Client'

      client_source.joins(:source_clients).
        where(id: @destinations.keys).
        select(:id, source_client_table[:PersonalID], source_client_table[:data_source_id]).
        pluck(:id, source_client_table[:PersonalID], source_client_table[:data_source_id]).
        group_by(&:first)

      @destinations.each do |id, _|
        client = client_source.find(id)
        @destinations[id][:source_personal_ids] = client.source_clients.pluck(:PersonalID, :data_source_id)
      end
    end

    def load_service_history_enrollments(batch)
      service_history_source.entry.
        where(client_id: batch).
        group(:client_id).
        pluck(:client_id, nf( 'COUNT', [she_t[:enrollment_group_id]] ).to_sql).
      each do |id, enrollment_count|
        @destinations[id][:service_history][:enrollments] = enrollment_count
      end
    end

    def load_service_history_exits(batch)
      service_history_source.exit.
        where(client_id: batch).
        group(:client_id).
        pluck(:client_id, nf( 'COUNT', [she_t[:enrollment_group_id]] ).to_sql).
      each do |id, exit_count|
        @destinations[id][:service_history][:exits] = exit_count
      end
    end

    def load_source_enrollments(batch)
      # Limit to only enrollments that have projects
      client_source.joins(source_enrollments: :project).
        where(id: batch).
        group(:id).
        pluck(:id, nf( 'COUNT', [nf('DISTINCT', [e_t[:EnrollmentID], e_t[:data_source_id]])] ).to_sql).
      each do |id, source_enrollment_count|
        @destinations[id][:source][:enrollments] = source_enrollment_count
      end
    end

    def load_source_exits(batch)
      # this is a bit nasty, but we sometimes have two exits for a single enrollment
      # which shouldn't happen.  We'll get around it by counting carefully.
      # Also limit to only exits with enrollments that have projects
      client_source.joins(source_exits: {enrollment: :project}).
        where(id: batch).
        group(:id).
        pluck(
          :id,
          nf('COUNT', [nf('DISTINCT', [ex_t[:EnrollmentID], ex_t[:PersonalID], ex_t[:data_source_id]])]).to_sql
        ).
      each do |id, source_exit_count|
        @destinations[id][:source][:exits] = source_exit_count
      end
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def enrollment_source
      GrdaWarehouse::Hud::Enrollment
    end

    def exit_source
      GrdaWarehouse::Hud::Exit
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def clients_processed_source
      GrdaWarehouse::WarehouseClientsProcessed.where(routine: 'service_history')
    end

  end
end
