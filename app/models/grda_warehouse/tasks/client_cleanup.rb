# NOTE: To force a rebuild that includes data that isn't the dates involved, you need to 
# also set the processed_hash on the enrollment to nil

module GrdaWarehouse::Tasks
  class ClientCleanup
    include NotifierConfig
    include ArelHelper
    require 'ruby-progressbar'
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize(max_allowed=200, bogus_notifier=false, changed_client_date: 2.weeks.ago.to_date, debug: false, dry_run: false, show_progress: false)
      @max_allowed = max_allowed
      setup_notifier('Client Cleanup')
      self.logger = Rails.logger
      @debug = debug
      @soft_delete_date = Time.now
      @changed_client_date = changed_client_date
      @dry_run = dry_run
      @show_progress = show_progress
    end
    def run!
      remove_unused_warehouse_clients_processed()
      GrdaWarehouseBase.transaction do
        @clients = find_unused_destination_clients
        debug_log "Found #{@clients.size} unused destination clients"
        remove_unused_service_history
        invalidate_incorrect_family_enrollments()
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
      if ! @dry_run
        adder = GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true)
        debug_log "Rebuilding service history for #{adder.clients_needing_update_count} clients"
        adder.run!
      end
    end

    def find_unused_destination_clients
      all_destination_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      active_destination_clients = GrdaWarehouse::WarehouseClient.joins(:source).pluck(:destination_id)
      all_destination_clients - active_destination_clients
    end

    def invalidate_incorrect_family_enrollments
      debug_log "Checking for enrollments flagged as individual where they should be family"
      query = GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(:project).merge(
              GrdaWarehouse::Hud::Project.family
            ).where(presented_as_individual: true)
        )
      count = query.count
      debug_log "Found #{count}"
      if count > 0
        @notifier.ping "Invalidating #{count} enrollments marked as individual where they should be family"  if @send_notifications
        query.update_all(processed_as: nil, processed_hash: nil)
      end

      debug_log "Checking for enrollments flagged as family where they should be individual"
      query = GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(:project).merge(
              GrdaWarehouse::Hud::Project.serves_individuals_only
            ).where(presented_as_individual: false)
        )
      count = query.count
      debug_log "Found #{count}"
      if count > 0
        @notifier.ping "Invalidating #{count} enrollments marked as family where they should be individual"  if @send_notifications
        query.update_all(processed_as: nil, processed_hash: nil)
      end
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
        if ! @dry_run
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
    end

    def choose_attributes_from_sources dest_attr, source_clients
      dest_attr = choose_best_name(dest_attr, source_clients)
      dest_attr = choose_best_ssn(dest_attr, source_clients)
      dest_attr = choose_best_dob(dest_attr, source_clients)
      dest_attr = choose_best_veteran_status(dest_attr, source_clients)
      dest_attr = choose_best_gender(dest_attr, source_clients)

      dest_attr
    end

    def choose_best_name dest_attr, source_clients
      # Get the best name (has name and quality is full or partial, oldest breaks the tie)
      non_blank_names = source_clients.select{|sc| (sc[:FirstName].present? or sc[:LastName].present?)}
      if non_blank_names.any?
        best_name_client = non_blank_names.sort do |a, b| 
          comp = b[:NameDataQuality] <=> a[:NameDataQuality] # Desc
          if comp == 0
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end.last
        if best_name_client.present?
          dest_attr[:FirstName] = best_name_client[:FirstName]
          dest_attr[:LastName] = best_name_client[:LastName]
        end
      end
      dest_attr
    end

    def choose_best_ssn dest_attr, source_clients
      # Get the best SSN (has value and quality is full or partial, oldest breaks the tie)
      non_blank_ssn = source_clients.select{|sc| sc[:SSN].present?}
      if non_blank_ssn.any?
        dest_attr[:SSN] = non_blank_ssn.sort do |a, b| 
          comp = b[:SSNDataQuality] <=> a[:SSNDataQuality] # Desc
          if comp == 0
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end.last[:SSN]
      else
        dest_attr[:SSN] = nil if dest_attr[:SSN].present? # none of the records have one now
      end
      dest_attr
    end

    def choose_best_veteran_status dest_attr, source_clients
      # Get the best Veteran status (has 0/1, newest breaks the tie)
      no_yes = [0, 1]
      yes_no_vet_status_clients = source_clients.select{|sc| no_yes.include?(sc[:VeteranStatus])}
      if !no_yes.include?(dest_attr[:VeteranStatus]) or yes_no_vet_status_clients.any?
        yes_no_vet_status_clients = source_clients if yes_no_vet_status_clients.none? #if none have yes/no we consider them all in the sort test
        dest_attr[:VeteranStatus] = yes_no_vet_status_clients.sort{|a, b| a[:DateUpdated] <=> b[:DateUpdated]}.last[:VeteranStatus]
      end
      dest_attr
    end

    def choose_best_dob dest_attr, source_clients
      # Get the best DOB (has value and quality is full or partial, oldest breaks the tie)
      non_blank_dob = source_clients.select{|sc| sc[:DOB].present?}
      if non_blank_dob.any?
        dest_attr[:DOB] = non_blank_dob.sort do |a, b| 
          comp = b[:DOBDataQuality] <=> a[:DOBDataQuality] # Desc
          if comp == 0
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end.last[:DOB]
      else
        dest_attr[:DOB] = nil if dest_attr[:DOB].present? # none of the records have one now
      end
      dest_attr
    end

    def choose_best_gender dest_attr, source_clients
      # Get the best Gender (has 0..4, newest breaks the tie)
      known_values = [0, 1, 2, 3, 4]
      known_value_gender_clients = source_clients.select{|sc| known_values.include?(sc[:Gender])}
      if !known_values.include?(dest_attr[:Gender]) or known_value_gender_clients.any?
        known_value_gender_clients = source_clients if known_value_gender_clients.none? #if none have known values we consider them all in the sort test
        dest_attr[:Gender] = known_value_gender_clients.sort{|a, b| a[:DateUpdated] <=> b[:DateUpdated]}.last[:Gender]
      end
      dest_attr
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
    #     e. Veteran Status (if yes or no)
    #   3. Never remove attribute unless it doesn't exist in any of the sources (never remove name)
    def update_client_demographics_based_on_sources
      batch_size = 1000
      processed = 0
      changed = {
        dobs: Set.new,
        genders: Set.new,
        veteran_statuses: Set.new,
        new_vets: Set.new,
        newly_not_vets: Set.new,
      }
      munge_clients = clients_to_munge
      client_source = GrdaWarehouse::Hud::Client
      total_clients = munge_clients.size
      logger.info "Munging #{munge_clients.size} clients"
      if @show_progress
        progress = ProgressBar.create(starting_at: 0, total: total_clients, format: 'Munging Client Data: %a %E |%B| %c of %C')
      end
      batches = munge_clients.each_slice(batch_size)
      batches.each do |batch|
        batch.each do |dest_id|
          dest = client_source.find(dest_id)
          source_clients = dest.source_clients.
            pluck(*client_columns.values).
            map do |row|
              Hash[client_columns.keys.zip(row)]
            end
          dest_attr = dest.attributes.with_indifferent_access.slice(*client_columns.keys)
          choose_attributes_from_sources(dest_attr, source_clients)

          # invalidate client if DOB has changed
          if dest.DOB != dest_attr[:DOB]
            logger.info "Invalidating service history for #{dest.id}"
            dest.invalidate_service_history unless @dry_run
          end
          # We can speed this up if we want later.  If there's only one source client and the 
          # updated dates match, there's no need to update the destination
          dest.update(dest_attr) unless @dry_run
          changed[:dobs] << dest.id if dest.DOB != dest_attr[:DOB]
          changed[:genders] << dest.id if dest.Gender != dest_attr[:Gender]
          changed[:veteran_statuses] << dest.id if dest.VeteranStatus != dest_attr[:VeteranStatus]
          changed[:new_vets] << dest.id if dest.VeteranStatus != 1 && dest_attr[:VeteranStatus] == 1
          changed[:newly_not_vets] << dest.id if dest.VeteranStatus == 1 && dest_attr[:VeteranStatus] == 0
          if @show_progress
            progress.progress += 1
          end
        end
        processed += batch_size
        logger.info "Updated demographics for #{processed} destination clients"
      end
      if @debug
        logger.debug '=========== Changed Counts ============'
        logger.debug changed.map{|k,ids| [k, ids.count]}.to_h.inspect
        logger.debug changed.inspect
        logger.debug '=========== End Changed Counts ============'
      end
    end

    def client_columns 
      @client_columns ||= {
        FirstName: c_t[:FirstName].as('FirstName').to_sql, 
        LastName: c_t[:LastName].as('LastName').to_sql, 
        SSN: c_t[:SSN].as('SSN').to_sql, 
        DOB: c_t[:DOB].as('DOB').to_sql,
        Gender: c_t[:Gender].as('Gender').to_sql,
        VeteranStatus: c_t[:VeteranStatus].as('VeteranStatus').to_sql, 
        NameDataQuality: cl(c_t[:NameDataQuality], 99).as('NameDataQuality').to_sql, 
        SSNDataQuality: cl(c_t[:SSNDataQuality], 99).as('SSNDataQuality').to_sql, 
        DOBDataQuality: cl(c_t[:DOBDataQuality], 99).as('DOBDataQuality').to_sql, 
        DateCreated: cl(c_t[:DateCreated], 10.years.ago.to_date).as('DateCreated').to_sql,
        DateUpdated: cl(c_t[:DateUpdated], 10.years.ago.to_date).as('DateUpdated').to_sql,
      }
    end

    def clients_to_munge
      debug_log "Check any client who's source has been updated in the past week"
      wc_t = GrdaWarehouse::WarehouseClient.arel_table
      updated_client_ids = GrdaWarehouse::Hud::Client.source.where(c_t[:DateUpdated].gt(@changed_client_date)).select(:id).pluck(:id)
      @to_update = GrdaWarehouse::WarehouseClientsProcessed.service_history.
        joins(:warehouse_client).
        where(wc_t[:source_id].in(updated_client_ids)).
        distinct.
        pluck(:client_id)
      logger.info "...found #{@to_update.size}."
      @to_update
    end

    def debug_log message
      logger.info message if @debug
    end

    # Sometimes client merging doesn't do a very good job of cleaning up
    # the service history table, just make sure we don't have any records 
    # for clients that no longer exist
    def remove_unused_service_history
      sh_client_ids = service_history_source.entry.distinct.pluck(:client_id)
      client_ids = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      non_existant_client_ids = sh_client_ids - client_ids
      if non_existant_client_ids.any?
        if non_existant_client_ids.size > @max_allowed
          @notifier.ping "Found #{non_existant_client_ids.size} clients in the service history table with no corresponding destination client. \nRefusing to remove so many service_history records.  The current threshold is *#{@max_allowed}* clients. You should come back and run this manually `bin/rake grda_warehouse:clean_clients[#{non_existant_client_ids.size}]` after you determine there isn't a bug." if @send_notifications
          return
        end
        debug_log "Removing service history for #{non_existant_client_ids.count} clients who no longer have client records"
        if ! @dry_run
          service_history_source.where(client_id: non_existant_client_ids).delete_all
        end
      end
    end

    def clean_service_history
      return unless @clients.any?
      sh_size = service_history_source.where(client_id: @clients).count
      if @clients.size > @max_allowed
        @notifier.ping "Found #{@clients.size} clients needing cleanup. \nRefusing to cleanup so many clients.  The current threshold is *#{@max_allowed}*. You should come back and run this manually `bin/rake grda_warehouse:clean_clients[#{@clients.size}]` after you determine there isn't a bug." if @send_notifications
        @clients = []
        return
      end
      logger.info "Deleting Service History for #{@clients.size} clients comprising #{sh_size} records"
      if ! @dry_run
        service_history_source.where(client_id: @clients).delete_all
      end
    end

    private def clean_warehouse_clients_processed
      return unless @clients.any?
      if ! @dry_run
        GrdaWarehouse::WarehouseClientsProcessed.where(client_id: @clients).delete_all
      end
    end

    def remove_unused_warehouse_clients_processed
      processed_ids = GrdaWarehouse::WarehouseClientsProcessed.pluck(:client_id)
      destination_client_ids = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      to_remove = processed_ids - destination_client_ids
      if to_remove.any? && ! @dry_run
        GrdaWarehouse::WarehouseClientsProcessed.where(client_id: to_remove).delete_all
      end
    end

    private def clean_warehouse_clients
      return unless @clients.any?
      if ! @dry_run
        GrdaWarehouse::WarehouseClient.where(destination_id: @clients).update_all(deleted_at: @soft_delete_date)
      end
    end

    private def clean_hmis_clients
      return unless @clients.any?
      if ! @dry_run
        GrdaWarehouse::HmisClient.where(client_id: @clients).delete_all
      end
    end

    private def clean_destination_clients
      return unless @clients.any?
      if ! @dry_run
        GrdaWarehouse::Hud::Client.where(id: @clients).update_all(DateDeleted: @soft_delete_date)
      end
    end

    def fix_incorrect_ages_in_service_history
      logger.info "Finding any clients with incorrect ages in the last 3 years of service history and invalidating them."
      incorrect_age_clients = Set.new
      less_than_zero = Set.new
      invalidate_clients = Set.new
      service_history_ages = service_history_source.entry.
        pluck(:client_id, :age, :first_date_in_program)
      clients = GrdaWarehouse::Hud::Client.
        where(id:service_history_source.entry.
          distinct.select(:client_id)).
        pluck(:id, :DOB).
        map.to_h
      
      service_history_ages.each do |id, age, entry_date|
        next unless dob = clients[id] # ignore blanks
        client_age = GrdaWarehouse::Hud::Client.age(date: entry_date, dob: dob)
        incorrect_age_clients << id if age.present? && (age != client_age || age < 0)
        less_than_zero << id if age.present? && age < 0
        invalidate_clients << id if age.present? && age != client_age
      end
      msg =  "Invalidating #{incorrect_age_clients.size} clients because ages don't match the service history."
      msg +=  " Of the #{incorrect_age_clients.size} clients found, #{less_than_zero.size} have ages in at least one enrollment where they are less than 0." if less_than_zero.size > 0
      logger.info msg
      @notifier.ping msg if @send_notifications
      # Only invalidate clients if the age is wrong, if it's less than zero but hasn't changed, this is just wasted effort
      if ! @dry_run
        GrdaWarehouse::Hud::Client.where(id: invalidate_clients.to_a).
          each(&:invalidate_service_history)
      end
    end

    def add_missing_ages_to_service_history
      logger.info "Finding any clients with DOBs with service histories missing ages..."
      with_dob = GrdaWarehouse::Hud::Client.destination.where.not(DOB: nil).pluck(:id)
      without_dob = service_history_source.where.not(record_type: 'first').
        where(age: nil).select(:client_id).distinct.pluck(:client_id)
      to_fix = with_dob & without_dob
      logger.info "... found #{to_fix.size}"
      if to_fix.size > 100
        @notifier.ping "Found #{to_fix.size} clients with dates of birth and service histories missing those dates.  This should not be happening.  \n\nLogical reasons include: a new import brought along a client DOB where we didn't have one before, but also had changes to enrollment, exit or services." if @send_notifications
      end
      if ! @dry_run
        to_fix.each do |client_id|
          client = GrdaWarehouse::Hud::Client.find(client_id)
          GrdaWarehouse::Hud::Enrollment.where(
            id: client.service_history.
              where(age: nil).
              joins(:enrollment).
              select(e_t[:id].as('id').to_sql)
          ).update_all(processed_as: nil)
          client.invalidate_service_history   
        end
      end
    end

    private def client_age_at date
      return unless @client.DOB.present? && date.present?
      dob = @client.DOB
      age = date.year - dob.to_date.year
      age -= 1 if dob.to_date > date.years_ago( age )
      age
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
  end
end
