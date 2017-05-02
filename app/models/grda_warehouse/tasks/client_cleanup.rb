module GrdaWarehouse::Tasks
  class ClientCleanup
    require 'ruby-progressbar'
    attr_accessor :logger, :send_notifications
    def initialize(max_allowed=200, bogus_notifier=false)
      @max_allowed = max_allowed
      @send_notifications = Rails.env.development? || Rails.env.production?
      if @send_notifications
        slack_url = Rails.application.config_for(:exception_notifier)['slack']['webhook_url']
        channel = Rails.application.config_for(:exception_notifier)['slack']['channel']
        @notifier = Slack::Notifier.new slack_url, channel: channel, username: 'ClientCleanup'
      end
      self.logger = Rails.logger
    end
    def run!
      GrdaWarehouseBase.transaction do 
        @clients = find_unused_destination_clients
        if @clients.any?
          clean_service_history
          clean_warehouse_clients_processed
          clean_warehouse_clients
          clean_hmis_clients
          clean_destination_clients
        end
      end
      update_client_demographics_based_on_sources
      add_missing_ages_to_service_history
    end

    private def find_unused_destination_clients
      all_destination_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      active_destination_clients = GrdaWarehouse::WarehouseClient.joins(:source).pluck(:destination_id)
      all_destination_clients - active_destination_clients
    end

    # Populate source client changes onto the destination client
    # Loop over all destination clients
    #   1. Sort source clients by UpdatedDate desc
    #   2. Walking down the source clients, update destination with the first found attribute 
    #     of the following attributes
    #     a. SSN
    #     b. DOB
    #     c. FirstName
    #     d. LastName
    #     e. Veteran Status (if yes)
    #   3. Never remove attribute unless it doesn't exist in any of the sources (never remove name)
    def update_client_demographics_based_on_sources
      batch_size = 1000
      processed = 0
      munge_clients = clients_to_munge
      client_source = GrdaWarehouse::Hud::Client
      total_clients = munge_clients.size
      logger.info "Munging #{munge_clients.size} clients"
      progress = ProgressBar.create(starting_at: 0, total: total_clients, format: 'Munging Client Data: %a %E |%B| %c of %C')
      attributes = [:FirstName, :LastName, :SSN, :DOB, :VeteranStatus, :DateUpdated]
      removable = [:SSN, :DOB]
      batches = munge_clients.each_slice(batch_size)
      batches.each do |batch|
        batch.each do |dest_id|
          dest = client_source.find(dest_id)
          # Sort newest first so we don't update the name on the destination client
          sql = dest.source_clients.select(attributes).order(DateUpdated: :desc).to_sql
          source_clients = client_source.
            connection.raw_connection.execute(sql)
            .each(as: :hash).
            map(&:with_indifferent_access)
          dest_attr = attributes.map{|m| [m, nil]}.to_h
          source_clients.each do |sc|
            attributes.each do |attribute|
              dest_attr[attribute] = sc[attribute] if dest_attr[attribute].blank? && sc[attribute].present?
              # if we have any yes answers for veteran status, trump everything else
              # Per DND 2/15/2017 this should now be set to the most recently changed
              # source client
              # dest_attr[attribute] = sc[attribute] if attribute == :VeteranStatus && sc[attribute] == 1
            end
          end
          # Always use the most recently updated 
          dest_attr[:VeteranStatus] = source_clients.first[:VeteranStatus]

          # See if we should remove anything
          removable.each do |attribute|
            # if we have no instances of this data bit
            if dest[attribute].present? && source_clients.map{|m| m[attribute]}.uniq.compact.empty?
              dest_attr[attribute] = nil
            end
          end
          # invalidate client if DOB has changed
          if dest.DOB != dest_attr[:DOB]
            logger.info "Invalidating service history for #{dest.id}"
            dest.invalidate_service_history
          end
          # We can speed this up if we want later.  If there's only one source client and the 
          # updated dates match, there's no need to update the destination
          dest.update(dest_attr)
          progress.progress += 1
        end
        processed += batch_size
        logger.info "Updated demographics for #{processed} destination clients"
      end
      GrdaWarehouse::Tasks::AddServiceHistory.new.run!
    end

    # Determine who has changed data since the last import
    # This is stolen from and dependent on Generate Service History 
    def clients_to_munge
      g_service_history = GrdaWarehouse::Tasks::GenerateServiceHistory.new
      @to_update = []
      sql = GrdaWarehouse::WarehouseClientsProcessed.service_history.select(:client_id, :last_service_updated_at).to_sql
      GrdaWarehouseBase.connection.select_rows(sql).each do |client_id, last_service_updated_at|
        # Ignore anyone who no longer has any active source clients
        next unless g_service_history.client_sources[client_id].present?
        # If newly imported data is newer than the date stored the last time we generated, regenerate
        last_modified = g_service_history.max_date_updated_for_destination_id(client_id)
        if last_service_updated_at.nil?
          @to_add << client_id  
        elsif last_modified.nil? || last_modified > last_service_updated_at
          @to_update << client_id
        end
      end
      @to_update
    end

    private def clean_service_history
      return unless @clients.any?
      sh_size = GrdaWarehouse::ServiceHistory.where(client_id: @clients).count
      if @clients.size > @max_allowed
        @notifier.ping "Found #{@clients.size} clients needing cleanup. \nRefusing to cleanup so many clients.  The current threshold is *#{@max_allowed}*. You should come back and run this manually `bin/rake grda_warehouse:clean_clients[#{@clients.size}]` after you determine there isn't a bug." if @send_notifications
        @clients = []
        return
      end
      logger.info "Deleting Service History for #{@clients.size} clients comprising #{sh_size} records"
      GrdaWarehouse::ServiceHistory.where(client_id: @clients).delete_all
    end

    private def clean_warehouse_clients_processed
      return unless @clients.any?
      GrdaWarehouse::WarehouseClientsProcessed.where(client_id: @clients).delete_all
    end

    private def clean_warehouse_clients
      return unless @clients.any?
      GrdaWarehouse::WarehouseClient.where(destination_id: @clients).delete_all
    end

    private def clean_hmis_clients
      return unless @clients.any?
      GrdaWarehouse::HmisClient.where(client_id: @clients).delete_all
    end

    private def clean_destination_clients
      return unless @clients.any?
      GrdaWarehouse::Hud::Client.where(id: @clients).update_all(DateDeleted: Time.now)
    end

    private def add_missing_ages_to_service_history
      logger.info "Finding any clients with DOBs with service histories missing ages..."
      with_dob = GrdaWarehouse::Hud::Client.destination.where.not(DOB: nil).pluck(:id)
      without_dob = GrdaWarehouse::ServiceHistory.where.not(record_type: 'first').where(age: nil).select(:client_id).distinct.pluck(:client_id)
      to_fix = with_dob & without_dob
      logger.info "... found #{to_fix.size}"
      if to_fix.size > 100
        @notifier.ping "Found #{to_fix.size} clients with dates of birth and service histories missing those dates.  This should not be happening.  \n\nLogical reasons include: a new import brought along a client DOB where we didn't have one before, but also had changes to enrollment, exit or services." if @send_notifications
      end
      to_fix.each do |client_id|
        @client = GrdaWarehouse::Hud::Client.find(client_id)
        first_service = GrdaWarehouse::ServiceHistory.where(age: nil, client_id: client_id).order(date: :asc).first
        last_service = GrdaWarehouse::ServiceHistory.where(age: nil, client_id: client_id).order(date: :desc).first
        current_age = client_age_at(first_service.date)
        start_date = @client.DOB + current_age.years
        end_date = @client.DOB + (current_age + 1).years - 1.day
        while start_date <= last_service.date
          # Update service history missing age between start_date and end_date
          # puts "age: #{current_age}, dob: #{@client.DOB} first_service: #{first_service.date} last_service: #{last_service.date}"
          GrdaWarehouse::ServiceHistory.where(age: nil, client_id: client_id).where(['date between ? and ?', start_date, end_date]).update_all(age: current_age)
          start_date += 1.year
          end_date += 1.year
          current_age += 1
        end
        # service_history = GrdaWarehouse::ServiceHistory.where(age: nil, client_id: client_id)
        # service_history.each do |sh|
        #   sh.update(age: client_age_at(sh.date))
        # end
      end
    end

    private def client_age_at date
      return unless @client.DOB.present? && date.present?
      dob = @client.DOB
      age = date.year - dob.to_date.year
      age -= 1 if dob.to_date > date.years_ago( age )
      age
    end
  end
end