# NOTE: To force a rebuild that includes data that isn't the dates involved, you need to 
# also set the processed_hash on the enrollment to nil

module GrdaWarehouse::Tasks
  class ClientCleanup
    include NotifierConfig
    include ArelHelper
    require 'ruby-progressbar'
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize(max_allowed=200, bogus_notifier=false, changed_client_date: 2.weeks.ago.to_date, debug: false)
      @max_allowed = max_allowed
      setup_notifier('Client Cleanup')
      self.logger = Rails.logger
      @debug = debug
      @soft_delete_date = Time.now
      @changed_client_date = changed_client_date
    end
    def run!
      remove_unused_warehouse_clients_processed()
      GrdaWarehouseBase.transaction do
        @clients = find_unused_destination_clients
        debug_log "Found #{@clients.size} unused destination clients"
        if @clients.any?
          debug_log "Deleting service history"
          clean_service_history
          debug_log "Deleting warehouse clients processed"
          clean_warehouse_clients_processed
          debug_log "Deleting warehouse clients"
          clean_warehouse_clients
          debug_log "Deleting hmis clients"
          clean_hmis_clients
          debug_log "Soft-deleting destination clients"
          clean_destination_clients
        end
      end
      update_client_demographics_based_on_sources()
      fix_incorrect_ages_in_service_history()
      add_missing_ages_to_service_history()
      rebuild_service_history_for_incorrect_clients()
    end

    def rebuild_service_history_for_incorrect_clients
      adder = GrdaWarehouse::Tasks::ServiceHistory::Add.new
      debug_log "Rebuilding service history for #{adder.clients_needing_update_count} clients"
      adder.run!
    end

    def find_unused_destination_clients
      all_destination_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      active_destination_clients = GrdaWarehouse::WarehouseClient.joins(:source).pluck(:destination_id)
      all_destination_clients - active_destination_clients
    end

    def remove_clients_without_enrollments!
      all_clients = GrdaWarehouse::Hud::Client.where(
        data_source_id: GrdaWarehouse::DataSource.importable.select(:id)
      ).distinct.pluck(:id)
      enrolled_clients = GrdaWarehouse::Hud::Client.joins(:enrollments).
      where(
        data_source_id: GrdaWarehouse::DataSource.importable.select(:id)
      ).distinct.pluck(:id)
      un_enrolled_clients = all_clients - enrolled_clients
      if un_enrolled_clients.any?
        deleted_at = Time.now
        debug_log "Removing #{un_enrolled_clients.size} un enrolled source clients and associated records.  Setting DateDeleted: #{deleted_at}"
        GrdaWarehouse::WarehouseClient.where(source_id: un_enrolled_clients).update_all(deleted_at: deleted_at)
        GrdaWarehouse::Hud::Exit.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::EnrollmentCoc.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::Disability.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::HealthAndDv.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::IncomeBenefit.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::EmploymentEducation.joins(:direct_client).
          where(Client: {id: un_enrolled_clients}).
          update_all(DateDeleted: deleted_at)
        GrdaWarehouse::Hud::Client.where(id: un_enrolled_clients).update_all(DateDeleted: deleted_at)
      end
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
          source_clients = dest.source_clients.order(DateUpdated: :desc).
            pluck(*attributes).
            map do |row|
              Hash[attributes.zip(row)]
            end
          dest_attr = dest.attributes.with_indifferent_access.slice(*attributes)
          source_clients.each do |sc|
            attributes.each do |attribute|
              dest_attr[attribute] = sc[attribute] if dest_attr[attribute].blank? && sc[attribute].present?
              # if we have any yes answers for veteran status, trump everything else
              # Per DND 2/15/2017 this should now be set to the most recently changed
              # source client
              # dest_attr[attribute] = sc[attribute] if attribute == :VeteranStatus && sc[attribute] == 1
              # 
              # Now, only replace yes or no with yes or no
              # or if we don't currently have a yes or no, replace it with the newest value
              if attribute == :VeteranStatus
                if (['1','2'].include?(dest_attr[attribute].to_s) && ['1','2'].include?(sc[attribute].to_s)) || ! ['1','2'].include?(dest_attr[attribute].to_s)
                  dest_attr[attribute] = sc[attribute]
                end
              end
            end
          end
          # Always use the most recently updated 
          binding.pry if source_clients.first.blank? && Rails.env.development?
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
            dest.force_full_service_history_rebuild
          end
          # We can speed this up if we want later.  If there's only one source client and the 
          # updated dates match, there's no need to update the destination
          dest.update(dest_attr)
          progress.progress += 1
        end
        processed += batch_size
        logger.info "Updated demographics for #{processed} destination clients"
      end
    end

    def clients_to_munge
      debug_log "Check any client who's source has been updated in the past week"
      wc_t = GrdaWarehouse::WarehouseClient.arel_table
      updated_client_ids = GrdaWarehouse::Hud::Client.source.where(c_t[:DateUpdated].gt(@changed_client_date)).select(:id).pluck(:id)
      @to_update = GrdaWarehouse::WarehouseClientsProcessed.service_history.
        joins(:warehouse_client).
        where(wc_t[:source_id].in(updated_client_ids)).
        pluck(:client_id)
      logger.info "...found #{@to_update.size}."
      @to_update
    end

    def debug_log message
      logger.info message if @debug
    end
    def clean_service_history
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

    def remove_unused_warehouse_clients_processed
      processed_ids = GrdaWarehouse::WarehouseClientsProcessed.pluck(:client_id)
      destination_client_ids = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      to_remove = processed_ids - destination_client_ids
      if to_remove.any?
        GrdaWarehouse::WarehouseClientsProcessed.where(client_id: to_remove).delete_all
      end
    end

    private def clean_warehouse_clients
      return unless @clients.any?
      GrdaWarehouse::WarehouseClient.where(destination_id: @clients).update_all(deleted_at: @soft_delete_date)
    end

    private def clean_hmis_clients
      return unless @clients.any?
      GrdaWarehouse::HmisClient.where(client_id: @clients).delete_all
    end

    private def clean_destination_clients
      return unless @clients.any?
      GrdaWarehouse::Hud::Client.where(id: @clients).update_all(DateDeleted: @soft_delete_date)
    end

    def fix_incorrect_ages_in_service_history
      logger.info "Finding any clients with incorrect ages in the last 3 years of service history and invalidating them."
      incorrect_age_clients = Set.new
      less_than_zero = Set.new
      service_history_ages = GrdaWarehouse::ServiceHistory.entry.
        pluck(:client_id, :age, :first_date_in_program)
      clients = GrdaWarehouse::Hud::Client.
        where(id:GrdaWarehouse::ServiceHistory.entry.
          distinct.select(:client_id)).
        pluck(:id, :DOB).
        map.to_h
      
      service_history_ages.each do |id, age, entry_date|
        next unless dob = clients[id] # ignore blanks
        client_age = GrdaWarehouse::Hud::Client.age(date: entry_date, dob: dob)
        incorrect_age_clients << id if age.present? && (age != client_age || age < 0)
        less_than_zero << id if age.present? && age < 0
      end
      msg =  "Invalidating #{incorrect_age_clients.size} clients because ages don't match the service history."
      msg +=  " Of the #{incorrect_age_clients.size} clients found, #{less_than_zero.size} have ages in at least one enrollment where they are less than 0." if less_than_zero.size > 0
      logger.info msg
      @notifier.ping msg if @send_notifications
      GrdaWarehouse::Hud::Client.where(id: incorrect_age_clients.to_a).
        map do |client|
          client.force_full_service_history_rebuild
        end
    end

    def add_missing_ages_to_service_history
      logger.info "Finding any clients with DOBs with service histories missing ages..."
      with_dob = GrdaWarehouse::Hud::Client.destination.where.not(DOB: nil).pluck(:id)
      without_dob = GrdaWarehouse::ServiceHistory.where.not(record_type: 'first').where(age: nil).select(:client_id).distinct.pluck(:client_id)
      to_fix = with_dob & without_dob
      logger.info "... found #{to_fix.size}"
      if to_fix.size > 100
        @notifier.ping "Found #{to_fix.size} clients with dates of birth and service histories missing those dates.  This should not be happening.  \n\nLogical reasons include: a new import brought along a client DOB where we didn't have one before, but also had changes to enrollment, exit or services." if @send_notifications
      end
      to_fix.each do |client_id|
        client = GrdaWarehouse::Hud::Client.find(client_id)
        GrdaWarehouse::Hud::Enrollment.where(
          id: client.service_history.
            where(age: nil).
            joins(:enrollment).
            select(e_t[:id].as('id').to_sql)
        ).update_all(processed_hash: nil)
        client.invalidate_service_history   
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
