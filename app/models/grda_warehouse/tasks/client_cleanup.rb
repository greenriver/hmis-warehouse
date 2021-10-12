###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: To force a rebuild that includes data that isn't the dates involved, you need to
# also set the processed_hash on the enrollment to nil

module GrdaWarehouse::Tasks
  class ClientCleanup
    include NotifierConfig
    include ArelHelper
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize(max_allowed = 1_000, _bogus_notifier = false, changed_client_date: 2.weeks.ago.to_date, debug: false, dry_run: false)
      @max_allowed = max_allowed
      setup_notifier('Client Cleanup')
      self.logger = Rails.logger
      @debug = debug
      @soft_delete_date = Time.now
      @changed_client_date = changed_client_date
      @dry_run = dry_run
    end

    def run!
      # FIXME: this should refuse to run if an import is in-process
      # See GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{data_source.id}")
      remove_unused_source_clients
      remove_unused_warehouse_clients_processed
      GrdaWarehouseBase.transaction do
        @clients = find_unused_destination_clients
        log "Found #{@clients.size} unused destination clients"
        remove_unused_service_history
        invalidate_incorrect_family_enrollments
        if @clients.any?
          log 'Deleting service history'
          clean_service_history
          log 'Deleting warehouse clients processed'
          clean_warehouse_clients_processed
          log 'Deleting warehouse clients'
          clean_warehouse_clients
          log 'Deleting hmis clients'
          clean_hmis_clients
          log 'Soft-deleting destination clients'
          clean_destination_clients
        end
      end
      update_client_demographics_based_on_sources
      fix_incorrect_ages_in_service_history
      add_missing_ages_to_service_history
      fix_incorrect_household_ids
      fix_incorrect_enrollment_coc_household_ids
      rebuild_service_history_for_incorrect_clients
    end

    # Find any heads of households where the same client has a duplicate HouseholdID
    # Update all members of the household where the HoH enrollment is closed with a new HouseholdID
    # where the members enrollment date falls between the HoH Entry and Exit dates inclusive
    def fix_incorrect_household_ids
      incorrect_households = GrdaWarehouse::Hud::Enrollment.heads_of_households.
        joins(:project).
        merge(
          GrdaWarehouse::Hud::Project.
          with_project_type(
            GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values.flatten,
          ),
        ).
        where.not(HouseholdID: nil).
        left_outer_joins(:exit).
        pluck(*household_id_columns.values).map do |row|
          Hash[household_id_columns.keys.zip(row)]
        end.group_by do |row|
          [
            row[:personal_id],
            row[:data_source_id],
            row[:household_id],
          ]
        end.select { |_, v| v.count > 1 }
      return unless incorrect_households

      incorrect_households.transform_values! do |households|
        households.each do |row|
          # make a new unique household id based on enrollment id, project, and data source
          row[:fixed_household_id] = Digest::MD5.hexdigest("e_#{row[:data_source_id]}_#{row[:project_id]}_#{row[:enrollment_id]}")
        end
      end
      log "Found #{incorrect_households.count} Heads of Household with at least two duplicate HouseholdIDs"
      to_update = 0

      # Fix all individual enrollments
      individuals = GrdaWarehouse::Hud::Enrollment.
        where(HouseholdID: incorrect_households.keys.map(&:last)).
        group(:ProjectID, :data_source_id, :HouseholdID).
        having('count(distinct("PersonalID")) = 1').
        count.
        keys
      individuals.each do |key|
        # NOTE: use delete to return value and remove key (in-place) from hash
        households = incorrect_households.delete(key)
        households&.each do |row|
          to_update += cleanup_household(row, individual: true)
        end
      end

      # Fix families
      incorrect_households.each_value do |households|
        households.each do |row|
          to_update += cleanup_household(row)
        end
      end
      if @dry_run
        log "Not updating #{to_update} enrollments (dry-run)"
      else
        log "Updated #{to_update} enrollments with incorrect HouseholdIDs"
      end
    end

    # Set any EnrollmentCoC.HouseholdIDs that don't match their
    # enrollments, to whatever is in their enrollment
    private def fix_incorrect_enrollment_coc_household_ids
      batch_size = 10_000
      ids = GrdaWarehouse::Hud::EnrollmentCoc.joins(:enrollment).where(
        ec_t[:HouseholdID].not_eq(e_t[:HouseholdID]).
        or(ec_t[:HouseholdID].eq(nil).and(e_t[:HouseholdID].not_eq(nil))),
      ).pluck(:id, e_t[:HouseholdID])
      ids.each_slice(batch_size) do |batch|
        GrdaWarehouse::Hud::EnrollmentCoc.import(
          [:id, :HouseholdID],
          batch,
          on_duplicate_key_update: { conflict_target: [:id], columns: [:HouseholdID] },
        )
      end
    end

    private def cleanup_household(household, individual: false)
      # If the enrollment is open, only update other open enrollments started on the same day
      # If the enrollment is closed, find any closed enrollment overlapping the range
      enrollments = GrdaWarehouse::Hud::Enrollment.where(
        data_source_id: household[:data_source_id],
        ProjectID: household[:project_id],
      )
      # If we are cleaning up an individual's enrollment, use the enrollment ID to find it
      # if we have a household, use the household ID
      if individual
        enrollments = enrollments.where(EnrollmentID: household[:enrollment_id])
      else
        enrollments = enrollments.where(HouseholdID: household[:household_id])
        # for ongoing enrollments, only look for entry dates greater than the HoH entry date
        if household[:exit_date].blank?
          enrollments = enrollments.where(EntryDate: household[:entry_date]..Date.current).
            left_outer_joins(:exit).
            where(ex_t[:ExitDate].eq(nil))
        else
          # If the entry date occurs on or after the exit date
          # just compare entry dates
          dates = if household[:entry_date] >= household[:exit_date]
            household[:entry_date]
          else
            household[:entry_date]...household[:exit_date]
          end
          enrollments = enrollments.joins(:exit).where(EntryDate: dates)
        end
      end

      # Update any closed enrollments that match this data source, project, household_id,
      # and date range, with a unique household id
      updated_count = enrollments.count
      unless @dry_run
        enrollments.update_all(
          HouseholdID: household[:fixed_household_id],
          original_household_id: household[:household_id],
          processed_as: nil,
        )
      end
      updated_count
    end

    private def household_id_columns
      {
        personal_id: e_t[:PersonalID],
        data_source_id: e_t[:data_source_id],
        entry_date: e_t[:EntryDate],
        exit_date: ex_t[:ExitDate],
        project_id: e_t[:ProjectID],
        enrollment_id: e_t[:EnrollmentID],
        household_id: e_t[:HouseholdID],
      }.freeze
    end

    def rebuild_service_history_for_incorrect_clients
      return if @dry_run

      adder = GrdaWarehouse::Tasks::ServiceHistory::Add.new
      log "Rebuilding service history for #{adder.clients_needing_update_count} clients"
      adder.run!
      adder.class.wait_for_processing
    end

    # Find any clients at data sources that come from HMIS systems
    # where the client has no enrollments.  These generally arise from
    # clients being merged or deleted in the sending system.
    def remove_unused_source_clients
      ds_ids = GrdaWarehouse::DataSource.importable.source.pluck(:id)
      with_enrollments = GrdaWarehouse::Hud::Client.source.
        where(data_source_id: ds_ids).
        joins(:enrollments).
        distinct.
        select(:id)
      # without_enrollments = GrdaWarehouse::Hud::Client.source.
      #   where(data_source_id: ds_ids).
      #   where.not(id: with_enrollments).
      #   distinct.
      #   select(:id)
      all_clients = GrdaWarehouse::Hud::Client.source.
        where(data_source_id: ds_ids).
        distinct.
        select(:id)
      without_enrollments = all_clients.pluck(:id) - with_enrollments.pluck(:id)
      deleted_at = DateTime.current
      log "Setting DateDeleted for #{without_enrollments.count} clients"
      return if @dry_run

      without_enrollments.each_slice(500) do |batch|
        GrdaWarehouse::Hud::Client.where(id: batch).update_all(DateDeleted: deleted_at, source_hash: nil)
      end
    end

    def find_unused_destination_clients
      all_destination_clients = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      active_destination_clients = GrdaWarehouse::WarehouseClient.joins(:source).pluck(:destination_id)
      all_destination_clients - active_destination_clients
    end

    def invalidate_incorrect_family_enrollments
      log 'Checking for enrollments flagged as individual where they should be family'
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        invalidate_incorrect_family_when_infer_from_household_id
      else
        invalidate_incorrect_family_when_infer_from_project
      end
    end

    private def invalidate_incorrect_family_when_infer_from_project
      log 'Checking for enrollments flagged as individual where they should be family'
      query = GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(:project).merge(
              GrdaWarehouse::Hud::Project.family,
            ).where(presented_as_individual: true),
        )
      count = query.count
      log "Found #{count}"

      if count.positive?
        log "Invalidating #{count} enrollments marked as individual where they should be family"
        query.invalidate_processing! unless @dry_run
      end
      log 'Checking for enrollments flagged as family where they should be individual'
      query = GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(:project).merge(
              GrdaWarehouse::Hud::Project.serves_individuals_only,
            ).where(presented_as_individual: false),
        )
      count = query.count
      log "Found #{count}"
      return unless count.positive?

      log("Invalidating #{count} enrollments marked as family where they should be individual")
      query.invalidate_processing! unless @dry_run
    end

    private def invalidate_incorrect_family_when_infer_from_household_id
      # Use a fresh pull of IDS
      Rails.cache.delete('family-households')
      hmis_non_individuals = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.family_households.keys
      service_history_non_individuals = GrdaWarehouse::ServiceHistoryEnrollment.entry.where(presented_as_individual: false).distinct.pluck(:household_id, :project_id, :data_source_id)
      missing_non_individuals = service_history_non_individuals - hmis_non_individuals
      incorrectly_non_individuals = hmis_non_individuals - service_history_non_individuals

      count = missing_non_individuals.count
      log("Invalidating #{count} enrollments marked as individual where they should be family") if count.positive?
      count = incorrectly_non_individuals.count
      log("Invalidating #{count} enrollments marked as family where they should be individual") if count.positive?
      notes = ''

      # These are incorrect on the service history side
      missing_non_individuals.group_by do |_household_id, project_id, data_source_id|
        [project_id, data_source_id]
      end.each do |(project_id, data_source_id), batch|
        household_ids = batch.map(&:first)
        # This is a bit convoluted, but the usual joins weren't working
        service_history_query = GrdaWarehouse::ServiceHistoryEnrollment.
          entry.
          joins(:enrollment).
          where(data_source_id: data_source_id, project_id: project_id, household_id: household_ids)
        query = GrdaWarehouse::Hud::Enrollment.where(
          EnrollmentID: service_history_query.
            select(:enrollment_group_id),
          data_source_id: data_source_id,
          ProjectID: project_id,
        )

        if @dry_run
          notes << "Invalidating #{query.count} in ds_id: #{data_source_id} project_id: #{project_id}\n\t#{household_ids.inspect}\n"
        else
          query.invalidate_processing!
        end
      end

      # these are incorrect on the enrollment size
      incorrectly_non_individuals.group_by do |_household_id, project_id, data_source_id|
        [project_id, data_source_id]
      end.each do |(project_id, data_source_id), batch|
        household_ids = batch.map(&:first)
        query = GrdaWarehouse::Hud::Enrollment.
          where(data_source_id: data_source_id, ProjectID: project_id, HouseholdID: household_ids)
        if @dry_run
          notes << "Invalidating #{query.count} in ds_id: #{data_source_id} project_id: #{project_id}\n\t#{household_ids.inspect}"
        else
          query.invalidate_processing!
        end
      end

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
      log(notes) if @dry_run
    end

    def choose_attributes_from_sources dest_attr, source_clients
      dest_attr = choose_best_name(dest_attr, source_clients)
      dest_attr = choose_best_ssn(dest_attr, source_clients)
      dest_attr = choose_best_dob(dest_attr, source_clients)
      dest_attr = choose_best_veteran_status(dest_attr, source_clients)
      dest_attr = choose_best_gender(dest_attr, source_clients)
      dest_attr = choose_best_race(dest_attr, source_clients)
      dest_attr = choose_best_ethnicity(dest_attr, source_clients)

      dest_attr
    end

    def choose_best_name dest_attr, source_clients
      # Get the best name (has name and quality is full or partial, oldest breaks the tie)
      non_blank_names = source_clients.select { |sc| (sc[:FirstName].present? or sc[:LastName].present?) }
      if non_blank_names.any?
        best_name_client = non_blank_names.max do |a, b|
          comp = b[:NameDataQuality] <=> a[:NameDataQuality] # Desc
          if comp == 0 # rubocop:disable Style/NumericPredicate
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end
        if best_name_client.present?
          dest_attr[:FirstName] = best_name_client[:FirstName]
          dest_attr[:LastName] = best_name_client[:LastName]
        end
      end
      dest_attr
    end

    def choose_best_ssn dest_attr, source_clients
      # Get the best SSN (has value and quality is full or partial, oldest breaks the tie)
      non_blank_ssn = source_clients.select { |sc| sc[:SSN].present? }
      if non_blank_ssn.any?
        dest_attr[:SSN] = non_blank_ssn.max do |a, b|
          comp = b[:SSNDataQuality] <=> a[:SSNDataQuality] # Desc
          if comp == 0 # rubocop:disable Style/NumericPredicate
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end[:SSN]
      elsif dest_attr[:SSN].present?
        dest_attr[:SSN] = nil
      end
      dest_attr
    end

    def choose_best_veteran_status dest_attr, source_clients
      # Get the best Veteran status (has 0/1, newest breaks the tie)
      # As of 2/16/2019 calculate using if ever yes, override with verified_veteran_status == non_veteran
      if dest_attr[:verified_veteran_status] == 'non_veteran'
        dest_attr[:VeteranStatus] = 0
      elsif source_clients.map { |sc| sc[:VeteranStatus] }.include?(1)
        dest_attr[:VeteranStatus] = 1
      else
        dest_attr[:VeteranStatus] = source_clients.max do |a, b|
          a[:DateUpdated] <=> b[:DateUpdated]
        end[:VeteranStatus]
      end

      dest_attr
    end

    def choose_best_dob dest_attr, source_clients
      # Get the best DOB (has value and quality is full or partial, oldest breaks the tie)
      non_blank_dob = source_clients.select { |sc| sc[:DOB].present? }
      if non_blank_dob.any?
        dest_attr[:DOB] = non_blank_dob.max do |a, b|
          comp = b[:DOBDataQuality] <=> a[:DOBDataQuality] # Desc
          if comp == 0 # rubocop:disable Style/NumericPredicate
            comp = b[:DateCreated] <=> a[:DateCreated] # Desc
          end
          comp
        end[:DOB]
      elsif dest_attr[:DOB].present?
        dest_attr[:DOB] = nil
      end
      dest_attr
    end

    def choose_best_gender dest_attr, source_clients
      # Most recent 0 or 1 if no 0 or 1 use the most recent value
      # Valid responses for gender categories are [0, 1, 99]
      # Valid responses for GenderNone are [8, 9, 99] -- should be null if any other gender field contains a 1
      known_values = [0, 1]
      # Sort in reverse chronological order (newest first)
      sorted_source_clients = source_clients.sort_by.sort { |a, b| b[:DateUpdated] <=> a[:DateUpdated] }

      gender_columns.each do |col|
        sorted_source_clients.each do |source_client|
          value = source_client[col]
          current_value = dest_attr[col]
          # if we have a 0 or 1 use it
          # otherwise only replace if the current value isn't a 0 or 1

          dest_attr[col] = if current_value.blank?
            value
          elsif known_values.include?(value)
            value
          elsif !known_values.include?(current_value) && value.present?
            value
          else
            current_value
          end

          # Since these are sorted in reverse chronological order, if we hit a 1 or 0, we'll consider that
          # the destination client response
          break if known_values.include?(value)
        end
      end

      # if we have any yes responses, set this to nil, otherwise use the most-recent GenderNone response
      if dest_attr.values_at(*gender_columns).any?(1)
        dest_attr[:GenderNone] = nil
      else
        dest_attr[:GenderNone] = sorted_source_clients.first[:GenderNone]
      end
      dest_attr
    end

    private def gender_columns
      @gender_columns ||= ::HUD.gender_fields - [:GenderNone]
    end

    def choose_best_race dest_attr, source_clients
      # Most recent 0 or 1 if no 0 or 1 use the most recent value
      # Valid responses for race categories are [0, 1, 99]
      # Valid responses for RaceNone are [8, 9, 99] -- should be null if all other fields are 0 or 99
      known_values = [0, 1]
      # Sort in reverse chronological order (newest first)
      sorted_source_clients = source_clients.sort_by.sort { |a, b| b[:DateUpdated] <=> a[:DateUpdated] }

      race_columns.each do |col|
        sorted_source_clients.each do |source_client|
          value = source_client[col]
          current_value = dest_attr[col]
          # if we have a 0 or 1 use it
          # otherwise only replace if the current value isn't a 0 or 1
          dest_attr[col] = if current_value.blank?
            value
          elsif known_values.include?(value)
            value
          elsif !known_values.include?(current_value) && value.present?
            value
          else
            current_value
          end

          # Since these are sorted in reverse chronological order, if we hit a 1 or 0, we'll consider that
          # the destination client response
          break if known_values.include?(value)
        end
      end

      # if we have any yes responses, set this to nil, otherwise use the most-recent RaceNone response
      if dest_attr.values_at(*race_columns).any?(1)
        dest_attr[:RaceNone] = nil
      else
        dest_attr[:RaceNone] = sorted_source_clients.first[:RaceNone]
      end
      dest_attr
    end

    private def race_columns
      @race_columns ||= GrdaWarehouse::Hud::Client.race_fields.map(&:to_sym) - [:RaceNone]
    end

    def choose_best_ethnicity dest_attr, source_clients
      # Most recent 0 or 1 if no 0 or 1 use the most recent value
      known_values = [0, 1]
      # Sort in reverse chronological order (newest first)
      sorted_source_clients = source_clients.sort_by.sort { |a, b| b[:DateUpdated] <=> a[:DateUpdated] }
      col = :Ethnicity
      sorted_source_clients.each do |source_client|
        value = source_client[col]
        current_value = dest_attr[col]
        # if we have a 0 or 1 use it
        # otherwise only replace if the current value isn't a 0 or 1
        dest_attr[col] = if known_values.include?(value)
          value
        elsif !known_values.include?(current_value)
          value
        else
          current_value
        end

        # Since these are sorted in reverse chronological order, if we hit a 1 or 0, we'll consider that
        # the destination client response
        break if known_values.include?(value)
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
        females: Set.new,
        males: Set.new,
        nosinglegenders: Set.new,
        transgenders: Set.new,
        questionings: Set.new,
        gendernones: Set.new,
        veteran_statuses: Set.new,
        new_vets: Set.new,
        newly_not_vets: Set.new,
      }
      munge_clients = clients_to_munge
      client_source = GrdaWarehouse::Hud::Client
      log "Munging #{munge_clients.size} clients"
      batches = munge_clients.each_slice(batch_size)
      batches.each do |batch|
        batch.each do |dest_id|
          dest = client_source.find(dest_id)
          source_clients = dest.source_clients.
            pluck(*client_columns.values.map { |column| Arel.sql(column) }).
            map do |row|
              Hash[client_columns.keys.zip(row)]
            end
          dest_attr = dest.attributes.with_indifferent_access.slice(*client_columns.keys)
          dest_attr = choose_attributes_from_sources(dest_attr, source_clients)

          # invalidate client if DOB has changed
          if dest.DOB != dest_attr[:DOB]
            logger.debug "Invalidating service history for #{dest.id}"
            dest.invalidate_service_history unless @dry_run
          end
          # We can speed this up if we want later.  If there's only one source client and the
          # updated dates match, there's no need to update the destination
          dest.update(dest_attr) unless @dry_run
          changed[:dobs] << dest.id if dest.DOB != dest_attr[:DOB]
          changed[:females] << dest.id if dest.Female != dest_attr[:Female]
          changed[:males] << dest.id if dest.Male != dest_attr[:Male]
          changed[:nosinglegenders] << dest.id if dest.NoSingleGender != dest_attr[:NoSingleGender]
          changed[:transgenders] << dest.id if dest.Transgender != dest_attr[:Transgender]
          changed[:questionings] << dest.id if dest.Questioning != dest_attr[:Questioning]
          changed[:gendernones] << dest.id if dest.GenderNone != dest_attr[:GenderNone]
          changed[:veteran_statuses] << dest.id if dest.VeteranStatus != dest_attr[:VeteranStatus]
          changed[:new_vets] << dest.id if dest.VeteranStatus != 1 && dest_attr[:VeteranStatus] == 1
          changed[:newly_not_vets] << dest.id if dest.VeteranStatus == 1 && dest_attr[:VeteranStatus] == 0 # rubocop:disable Style/NumericPredicate
        end
        processed += batch_size
        logger.debug "Updated demographics for #{processed} destination clients"
      end
      return unless @debug

      logger.debug '=========== Changed Counts ============'
      logger.debug changed.map { |k, ids| [k, ids.count] }.to_h.inspect
      logger.debug changed.inspect
      logger.debug '=========== End Changed Counts ============'
    end

    def client_columns
      @client_columns ||= {
        FirstName: c_t[:FirstName].to_sql,
        LastName: c_t[:LastName].to_sql,
        SSN: c_t[:SSN].to_sql,
        DOB: c_t[:DOB].to_sql,
        Female: c_t[:Female].to_sql,
        Male: c_t[:Male].to_sql,
        NoSingleGender: c_t[:NoSingleGender].to_sql,
        Transgender: c_t[:Transgender].to_sql,
        Questioning: c_t[:Questioning].to_sql,
        GenderNone: c_t[:GenderNone].to_sql,
        VeteranStatus: c_t[:VeteranStatus].to_sql,
        verified_veteran_status: c_t[:verified_veteran_status].to_sql,
        NameDataQuality: cl(c_t[:NameDataQuality], 99).as('NameDataQuality').to_sql,
        SSNDataQuality: cl(c_t[:SSNDataQuality], 99).as('SSNDataQuality').to_sql,
        DOBDataQuality: cl(c_t[:DOBDataQuality], 99).as('DOBDataQuality').to_sql,
        DateCreated: cl(c_t[:DateCreated], 10.years.ago.to_date).as('DateCreated').to_sql,
        DateUpdated: cl(c_t[:DateUpdated], 10.years.ago.to_date).as('DateUpdated').to_sql,
        AmIndAKNative: cl(c_t[:AmIndAKNative], 99).as('AmIndAKNative').to_sql,
        Asian: cl(c_t[:Asian], 99).as('Asian').to_sql,
        BlackAfAmerican: cl(c_t[:BlackAfAmerican], 99).as('BlackAfAmerican').to_sql,
        NativeHIPacific: cl(c_t[:NativeHIPacific], 99).as('NativeHIPacific').to_sql,
        White: cl(c_t[:White], 99).as('White').to_sql,
        RaceNone: cl(c_t[:RaceNone], 99).as('RaceNone').to_sql,
        Ethnicity: cl(c_t[:Ethnicity], 99).as('Ethnicity').to_sql,
      }
    end

    def clients_to_munge
      log "Check any client who's source has been updated in the past week"
      wc_t = GrdaWarehouse::WarehouseClient.arel_table
      updated_client_ids = GrdaWarehouse::Hud::Client.source.where(c_t[:DateUpdated].gt(@changed_client_date)).select(:id).pluck(:id)
      @to_update = GrdaWarehouse::WarehouseClientsProcessed.service_history.
        joins(:warehouse_client).
        where(wc_t[:source_id].in(updated_client_ids)).
        distinct.
        pluck(:client_id)
      log "...found #{@to_update.size}."
      @to_update
    end

    def log message
      Rails.logger.info(message)
      @notifier.ping(message) if @send_notifications
    end

    # Sometimes client merging doesn't do a very good job of cleaning up
    # the service history table, just make sure we don't have any records
    # for clients that no longer exist
    def remove_unused_service_history
      sh_client_ids = service_history_source.entry.distinct.pluck(:client_id)
      client_ids = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      non_existant_client_ids = sh_client_ids - client_ids
      return unless non_existant_client_ids.any?

      # if non_existant_client_ids.size > @max_allowed
      #   @notifier.ping "Found #{non_existant_client_ids.size} clients in the service history table with no corresponding destination client. \nRefusing to remove so many service_history records.  The current threshold is *#{@max_allowed}* clients. You should come back and run this manually `bin/rake grda_warehouse:clean_clients[#{non_existant_client_ids.size}]` after you determine there isn't a bug." if @send_notifications
      #   return
      # end
      log "Removing service history for #{non_existant_client_ids.count} clients who no longer have client records"
      service_history_source.where(client_id: non_existant_client_ids).delete_all unless @dry_run
    end

    def clean_service_history
      return unless @clients.any?

      sh_size = service_history_source.where(client_id: @clients).count
      # if @clients.size > @max_allowed
      #   @notifier.ping "Found #{@clients.size} clients needing cleanup. \nRefusing to cleanup so many clients.  The current threshold is *#{@max_allowed}*. You should come back and run this manually `bin/rake grda_warehouse:clean_clients[#{@clients.size}]` after you determine there isn't a bug." if @send_notifications
      #   @clients = []
      #   return
      # end
      log "Deleting Service History for #{@clients.size} clients comprising #{sh_size} records"
      service_history_source.where(client_id: @clients).delete_all unless @dry_run
    end

    private def clean_warehouse_clients_processed
      return unless @clients.any?
      return if @dry_run

      GrdaWarehouse::WarehouseClientsProcessed.where(client_id: @clients).delete_all
    end

    def remove_unused_warehouse_clients_processed
      processed_ids = GrdaWarehouse::WarehouseClientsProcessed.pluck(:client_id)
      destination_client_ids = GrdaWarehouse::Hud::Client.destination.pluck(:id)
      to_remove = processed_ids - destination_client_ids
      return if to_remove.none? || @dry_run

      GrdaWarehouse::WarehouseClientsProcessed.where(client_id: to_remove).delete_all
    end

    private def clean_warehouse_clients
      return unless @clients.any?
      return if @dry_run

      GrdaWarehouse::WarehouseClient.where(destination_id: @clients).update_all(deleted_at: @soft_delete_date)
    end

    private def clean_hmis_clients
      return unless @clients.any?
      return if @dry_run

      GrdaWarehouse::HmisClient.where(client_id: @clients).delete_all
    end

    private def clean_destination_clients
      return unless @clients.any?
      return if @dry_run

      GrdaWarehouse::Hud::Client.where(id: @clients).update_all(DateDeleted: @soft_delete_date, source_hash: nil)
    end

    def fix_incorrect_ages_in_service_history
      log 'Finding any clients with incorrect ages in the last 3 years of service history and invalidating them.'
      incorrect_age_clients = Set.new
      less_than_zero = Set.new
      invalidate_clients = Set.new
      service_history_ages = service_history_source.entry.
        pluck(:client_id, :age, :first_date_in_program)
      clients = GrdaWarehouse::Hud::Client.
        where(id: service_history_source.entry.
          distinct.select(:client_id)).
        pluck(:id, :DOB).
        map.to_h

      service_history_ages.each do |id, age, entry_date|
        dob = clients[id]
        next unless dob # ignore blanks

        client_age = GrdaWarehouse::Hud::Client.age(date: entry_date, dob: dob)
        incorrect_age_clients << id if age.present? && (age != client_age || age < 0) # rubocop:disable Style/NumericPredicate
        less_than_zero << id if age.present? && age < 0 # rubocop:disable Style/NumericPredicate
        invalidate_clients << id if age.present? && age != client_age
      end
      msg = "Invalidating #{incorrect_age_clients.size} clients because ages don't match the service history."
      msg += " Of the #{incorrect_age_clients.size} clients found, #{less_than_zero.size} have ages in at least one enrollment where they are less than 0." if less_than_zero.size.positive?
      log msg
      # Only invalidate clients if the age is wrong, if it's less than zero but hasn't changed, this is just wasted effort
      return if @dry_run

      GrdaWarehouse::Hud::Client.where(id: invalidate_clients.to_a).
        each(&:invalidate_service_history)
    end

    def add_missing_ages_to_service_history
      log 'Finding any clients with DOBs with service histories missing ages...'
      with_dob = GrdaWarehouse::Hud::Client.destination.where.not(DOB: nil).pluck(:id)
      without_dob = service_history_source.where.not(record_type: 'first').
        where(age: nil).select(:client_id).distinct.pluck(:client_id)
      to_fix = with_dob & without_dob
      log "... found #{to_fix.size}"
      log "Found #{to_fix.size} clients with dates of birth and service histories missing those dates.  This should not be happening.  \n\nLogical reasons include: a new import brought along a client DOB where we didn't have one before, but also had changes to enrollment, exit or services." if to_fix.size > 100
      return if @dry_run

      to_fix.each do |client_id|
        client = GrdaWarehouse::Hud::Client.find(client_id)
        GrdaWarehouse::Hud::Enrollment.where(
          id: client.service_history_enrollments.
            where(age: nil).
            joins(:enrollment).
            select(e_t[:id].as('id').to_sql),
        ).invalidate_processing!
        client.invalidate_service_history
      end
    end

    private def client_age_at date
      return unless @client.DOB.present? && date.present?

      dob = @client.DOB
      age = date.year - dob.to_date.year
      age -= 1 if dob.to_date > date.years_ago(age)
      age
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
  end
end
