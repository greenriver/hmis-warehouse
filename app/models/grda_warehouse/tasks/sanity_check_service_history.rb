module GrdaWarehouse::Tasks
  class SanityCheckServiceHistory
    require 'ruby-progressbar'
    attr_accessor :logger, :send_notifications, :notifier_config

    def initialize(sample_size = 10, client_ids = [])
      @sample_size = sample_size
      @client_ids = client_ids
      @notifier_config = Rails.application.config_for(:exception_notifier) rescue nil
      @send_notifications = notifier_config && ( Rails.env.development? || Rails.env.production? )
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
        slack_url = notifier_config['slack']['webhook_url']
        channel   = notifier_config['slack']['channel']
        notifier  = Slack::Notifier.new slack_url, channel: channel, username: 'Service History Sanity Checker'
      end
      messages = []
      @destinations.each do |id, counts|
        if counts[:service_history].except(:service) != counts[:source].except(:service)
          msg = "Hey, the enrollment counts don't match for client: *#{id}* \n```#{counts.except(:source_personal_ids).inspect}```\nInvalidating service history for client."
          logger.warn msg
          messages << msg
          client_source.find(id).invalidate_service_history
        else
          # See if our service history counts are even close
          service_history_count = counts[:service_history].try(:[], :service) || 0
          service_count = counts[:source].try(:[], :service) || 0
          if (service_history_count - service_count).abs > 3
            msg = "Hey, the service history counts don't match for client: *#{id}* \n```source: #{service_count} service_history: #{service_history_count}```\nInvalidating service history for client."
            logger.warn msg
            messages << msg
            client_source.find(id).invalidate_service_history
          end
        end 
      end

      if messages.any?
        rebuilding_message = "Rebuilding service history for #{messages.size} invalidated clients."
        if send_notifications
          msg = messages.join("\n")
          msg += "\n\n#{rebuilding_message}"
          notifier.ping msg
        end
        logger.info rebuilding_message
        GrdaWarehouse::Tasks::AddServiceHistory.new.run!
      end
    end

    def choose_sample
      if @client_ids.any?
        destinations = @client_ids
      else
        destinations = clients_processed_source.random.limit(@sample_size).pluck(:client_id)
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
        pluck(:id, "#{source_client_table.name}.PersonalID", "#{source_client_table.name}.data_source_id").
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
        pluck(:client_id, 'COUNT(enrollment_group_id)').
      each do |id, enrollment_count|
        @destinations[id][:service_history][:enrollments] = enrollment_count
      end
    end

    def load_service_history_exits
      service_history_source.exit.
        where(client_id: @destinations.keys).
        group(:client_id).
        pluck(:client_id, 'COUNT(enrollment_group_id)').
      each do |id, exit_count|
        @destinations[id][:service_history][:exits] = exit_count
      end
    end

    def load_source_enrollments
      client_source.joins(:source_enrollments).
        where(id: @destinations.keys).
        group(:id).
        pluck(:id, 'COUNT(ProjectEntryID)').
      each do |id, source_enrollment_count|
        @destinations[id][:source][:enrollments] = source_enrollment_count
      end
    end

    def load_source_exits
      # this is a bit nasty, but we sometimes have two exits for a single enrollment
        # which shouldn't happen.  We'll get around it by counting carefully
      client_source.joins(:source_exits).
        where(id: @destinations.keys).
        group(:id).
        pluck(:id, 'COUNT(distinct [Exit].ProjectEntryID)').
      each do |id, source_exit_count|
        @destinations[id][:source][:exits] = source_exit_count
      end
    end

    def load_service_counts
      service_history_source.service.
        where(client_id: @destinations.keys).
        where(project_tracking_method: 3).
        group(:client_id).
        pluck(:client_id, 'COUNT(distinct checksum(date, enrollment_group_id))').
      each do |id, service_count|
        @destinations[id][:service_history][:service] = service_count
      end
    end

    def load_source_service_counts
      # Sometimes we see a service record duplicated, make sure we don't count
      # the duplicates
      client_source.joins(source_services: :project).
        where(id: @destinations.keys, project: {TrackingMethod: 3}).
        group(:id).
        pluck(:id, 'COUNT(distinct CHECKSUM([Services].DateProvided, [Services].ProjectEntryID))').
      each do |id, source_service_count|
        @destinations[id][:source][:service] = source_service_count
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
      GrdaWarehouse::ServiceHistory
    end

    def clients_processed_source
      GrdaWarehouse::WarehouseClientsProcessed.where(routine: 'service_history')
    end
    
  end
end
