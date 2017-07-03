module GrdaWarehouse::Tasks
  class SanityCheckServiceHistory
    require 'ruby-progressbar'
    include ArelHelper
    attr_accessor :logger, :send_notifications, :notifier_config
    MAX_ATTEMPTS = 3 # We'll check anything a few times, but don't run forever
    CACHE_KEY = 'sanity_check_service_history'

    def initialize(sample_size = 10, client_ids = [])
      @sample_size = sample_size
      @client_ids = client_ids
      @notifier_config = Rails.application.config_for(:exception_notifier)['slack'] rescue nil
      @send_notifications = notifier_config.present? && ( Rails.env.development? || Rails.env.production? )
      @logger = Rails.logger
      if @client_ids.any?
        @sample_size = @client_ids.size
      end
    end

    # Pick a sample of destination clients and compare the number of entry and exit records
    # they have in their source data to the number they have in their service history
    def run!
      logger.info "Sanity checking #{@sample_size} random clients..."
      choose_sample()
      # load_personal_ids()
      load_service_history_enrollments()
      load_service_history_exits()
      load_source_enrollments()
      load_source_exits()
      load_service_counts()
      load_source_service_counts()
      sanity_check()
      logger.info "...sanity check complete"
    end

    def sanity_check
      if send_notifications
        slack_url = notifier_config['webhook_url']
        channel   = notifier_config['channel']
        notifier  = Slack::Notifier.new slack_url, channel: channel, username: 'Service History Sanity Checker'
      end
      messages = []
      @destinations.each do |id, counts|
        if counts[:service_history].except(:service) != counts[:source].except(:service)
          msg = "```client: #{id} \n#{counts.except(:source_personal_ids).inspect}```\n"
          logger.warn msg
          messages << msg
          client_source.find(id).invalidate_service_history
          add_attempt(id)
        else
          # See if our service history counts are even close
          service_history_count = counts[:service_history].try(:[], :service) || 0
          service_count = counts[:source].try(:[], :service) || 0
          if (service_history_count - service_count).abs > 3
            msg = "```client: #{id} \nsource: #{service_count} service_history: #{service_history_count}```\n"
            logger.warn msg
            messages << msg
            client_source.find(id).invalidate_service_history
            add_attempt(id)
          end
        end 
      end
      update_attempts()
      if messages.any?
        rebuilding_message = "Rebuilding service history for #{messages.size} invalidated clients."
        if send_notifications
          msg = "Hey, the service history counts don't match for the following client(s).  Service histories have been invalidated.\n"
          msg += messages.join("\n")
          msg += "\n\n#{rebuilding_message}"
          notifier.ping msg
        end
        logger.info rebuilding_message
        GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
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
      @destinations = destinations.map{ |m| [m, {
        service_history: {
          enrollments: 0,
          exits: 0,
        },
        source: {
          enrollments: 0,
          exits: 0,
        },
        source_personal_ids: []
      }] }.to_h
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

    def load_service_history_enrollments
      service_history_source.entry.
        where(client_id: @destinations.keys).
        group(:client_id).
        pluck(:client_id, nf( 'COUNT', [sh_t[:enrollment_group_id]] ).to_sql).
      each do |id, enrollment_count|
        @destinations[id][:service_history][:enrollments] = enrollment_count
      end
    end

    def load_service_history_exits
      service_history_source.exit.
        where(client_id: @destinations.keys).
        group(:client_id).
        pluck(:client_id, nf( 'COUNT', [sh_t[:enrollment_group_id]] ).to_sql).
      each do |id, exit_count|
        @destinations[id][:service_history][:exits] = exit_count
      end
    end

    def load_source_enrollments
      # Limit to only enrollments that have projects
      client_source.joins(source_enrollments: :project).
        where(id: @destinations.keys).
        group(:id).
        pluck(:id, nf( 'COUNT', [enrollment_source.arel_table[:ProjectEntryID]] ).to_sql).
      each do |id, source_enrollment_count|
        @destinations[id][:source][:enrollments] = source_enrollment_count
      end
    end

    def load_source_exits
      # this is a bit nasty, but we sometimes have two exits for a single enrollment
      # which shouldn't happen.  We'll get around it by counting carefully.
      # Also limit to only exits with enrollments that have projects
      client_source.joins(source_exits: {enrollment: :project}).
        where(id: @destinations.keys).
        group(:id).
        pluck(
          :id, 
          nf('COUNT', [nf('DISTINCT', [exit_source.arel_table[:ProjectEntryID]])]).to_sql
        ).
      each do |id, source_exit_count|
        @destinations[id][:source][:exits] = source_exit_count
      end
    end

    def load_service_counts
      service_history_source.service.bed_night.
        where(client_id: @destinations.keys).
        group(:client_id).
        pluck(
          :client_id, 
          nf('COUNT', [nf('DISTINCT', [checksum(GrdaWarehouse::ServiceHistory, [sh_t[:enrollment_group_id], sh_t[:date]])])]).to_sql
        ).
      each do |id, service_count|
        @destinations[id][:service_history][:service] = service_count
      end
    end

    def load_source_service_counts
      # Sometimes we see a service record duplicated, make sure we don't count
      # the duplicates
      st = GrdaWarehouse::Hud::Service.arel_table
      @destinations.keys.each_slice(250) do |ids|
        client_source.joins(source_services: :project).
          where(id: ids, Project: {TrackingMethod: 3}).
          group(:id).
          pluck(
            :id,
            nf('COUNT', [nf('DISTINCT', [checksum(GrdaWarehouse::Hud::Service, [st[:DateProvided], st[:ProjectEntryID]])])]).to_sql 
          ).
        each do |id, source_service_count|
          @destinations[id][:source][:service] = source_service_count
        end
      end
    end

    def sh_t
      service_history_source.arel_table
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
      GrdaWarehouse::ServiceHistory
    end

    def clients_processed_source
      GrdaWarehouse::WarehouseClientsProcessed.where(routine: 'service_history')
    end
    
  end
end
