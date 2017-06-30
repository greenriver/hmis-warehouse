module GrdaWarehouse::Tasks::ServiceHistory
  class Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    include ArelHelper
    require 'ruby-progressbar'
    attr_accessor :logger, :send_notifications, :notifier_config

    def initialize
      self.logger = Rails.logger
      @notifier_config = Rails.application.config_for(:exception_notifier)['slack'] rescue nil
      @send_notifications = notifier_config.present? && ( Rails.env.development? || Rails.env.production? )
      if @send_notifications
        slack_url = notifier_config['webhook_url']
        channel   = notifier_config['channel']
        @notifier  = Slack::Notifier.new(slack_url, channel: channel, username: 'Service History Generator')
      end
      @sanity_check = Set.new
      @batch_size = 1000
    end

    def run!
      begin
        @rows_inserted = 0
        @progress_format = '%a: service_history_days_generated:%c (%R/sec)'
        @progress = ProgressBar.create(starting_at: 0, total: nil, format: @progress_format)
        @pb_output_for_log = ProgressBar::Outputs::NonTty.new(bar: @progress)
        @dry_run = ENV['DRY_RUN'].to_s.in? ['1','Y']
        tries ||= 0
        logger.info "Generating Service History #{'[DRY RUN!]' if @dry_run}"
        started_at = DateTime.now
        log = GrdaWarehouse::GenerateServiceHistoryLog.create(started_at: started_at)

        # Provide Application locking so we can be sure we aren't already generating history
        if service_history_source.advisory_lock_exists?('service_history')
          logger.warn "Service History Genration already running...exiting"
          return
        end
        # # Add MSSQL support to https://github.com/mceachen/with_advisory_lock see local gem
        service_history_source.with_advisory_lock('service_history') do
          remove_stale_history()
          build_history()
        end

        sanity_check()
        
        completed_at = DateTime.now
        log.assign_attributes(completed_at: completed_at, to_delete: @to_delete.size, to_add: @to_add_count, to_update: @to_update_count)
        unless @dry_run
          log.save
        end
      ensure
        Rails.cache.delete('sanity_check_count')
      end
    end

    def determine_clients_with_no_service_history
      # logger.info NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      logger.info "Finding clients without service histories..."
      @to_add = destination_client_scope.without_service_history.pluck(:id)
      @to_add_count = @to_add.size
      logger.info "...found #{@to_add_count}."

      @to_add
    end

    def clients_needing_updates
      logger.info "Finding clients needing updates..."
      # Add anyone who's history has changed since the last time we processed them
      sql = warehouse_clients_processed_source.service_history.select(:client_id, :last_service_updated_at).to_sql
      @to_update = [] # This will be converted to a hash later
      GrdaWarehouseBase.connection.select_rows(sql).each do |client_id, last_service_updated_at|
        # Fix the column type, select_rows now returns all strings
        client_id = service_history_source.column_types['client_id'].type_cast_from_database(client_id)
        last_service_updated_at = service_history_source.column_types['last_service_updated_at'].type_cast_from_database(last_service_updated_at)
        # Ignore anyone who no longer has any active source clients
        next unless source_clients_for(client_id).any?
        # If newly imported data is newer than the date stored the last time we generated, regenerate
        last_modified = max_date_updated_for_destination_id(client_id)
        if last_service_updated_at.nil?
          @to_add << client_id  
        elsif last_modified.nil? || last_modified > last_service_updated_at
          @to_update << [client_id, last_service_updated_at]
        end
      end
      @to_update = @to_update.uniq.to_h
      logger.info "...found #{@to_update.size}."
      @to_update
    end

    # Must be called after setting @to_update with clients_needing_updates()
    def clients_with_open_enrollments()
      # Finding any client with an open enrollment who just needs some days added
      logger.info "Finding existing clients with open enrollments (some will need days added)..."
      
      @to_patch = service_history_source.entry.
        where(last_date_in_program: nil).
        where(sh_t[:project_tracking_method].not_eq(3).or(sh_t[:project_tracking_method].eq(nil))). # ignore any night-by-night projects
        select(:client_id).
        distinct.
        pluck(:client_id)
      # Exclude anyone we're already planning to update
      @to_patch = @to_patch - @to_update.keys
      # @to_patch = [328572]
      logger.info "...found #{@to_patch.size}."
      @to_patch
    end

    def no_one_to_build?
      (@to_add + @to_patch).empty? && @to_update.empty?
    end

    # sanity check anyone we've touched
    def sanity_check
      batches = @sanity_check.each_slice(@batch_size)
      batches.each_with_index do |batch, index|
        log_and_send_message "Sanity Checking all #{@sanity_check.size} clients in batches of #{batch.size}.  Batch #{index + 1}"
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(1, batch).run!
      end
    end

    def log_and_send_message msg
      logger.info msg
      @notifier.ping msg if @send_notifications
    end

    def process_to_update
      clients_completed = 0
      # prepare to sanity check anyone we've touched
      @sanity_check += @to_update.keys
      # Process Updates
      log_and_send_message "Updating #{@to_update.size} clients in batches of #{@batch_size}"
      GC.start
      batches = @to_update.keys.each_slice(@batch_size)
      batches.each do |batch|
        prepare_for_batch(batch) # Limit fetching to the current batch
        # Setup a huge transaction, we'll commit frequently
        GrdaWarehouseBase.transaction do
          batch.each_with_index do |id,index|
            update(id)
            clients_completed += 1
            status('Updated', clients_completed, commit_after: 10, denominatar: @to_update.size)
          end
        end
        logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
        @batch = nil
      end
      @progress.refresh
    end

    def process_to_add
      msg =  "Processing #{@to_add.size} new/invalidated clients in batches of #{@batch_size}"
      log_and_send_message msg

      GC.start
      batches = @to_add.each_slice(@batch_size)
      # prepare to sanity check anyone we've touched
      @sanity_check += @to_add
      clients_completed = 0
      batches.each do |batch|
        prepare_for_batch(batch) # Limit fetching to the current batch
        # Setup a huge transaction, we'll commit frequently
        GrdaWarehouseBase.transaction do
          batch.each_with_index do |id,index|
            add(id)
            clients_completed += 1
            status('Added', clients_completed, commit_after: 10, denominatar: @to_add.size)
          end
        end
        logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
        @batch = nil
      end
      @progress.refresh
    end

    def process_to_patch
      log_and_send_message "Patching #{@to_patch.size} open enrollments..."
      batches = @to_patch.each_slice(10000)
      clients_completed = 0
      batches.each do |batch|
        prepare_for_batch(batch) # Limit fetching to the current batch
        # Setup a huge transaction, we'll commit frequently
        GrdaWarehouseBase.transaction do
          batch.each_with_index do |id,index|
            # ignore anyone with no source clients
            patch(id) if source_clients_for(id).any?
            clients_completed += 1
            status('Patched', clients_completed, commit_after: 10, denominatar: @to_patch.size)
          end
        end
        logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
        @batch = nil
      end
      @progress.refresh
    end

    # Reset cached variable so we can fetch a new set of clients
    def prepare_for_batch(batch)
      logger.info '  Preparing cache for batch...'
      @batch = batch
      @source_client_personal_ids = nil;  # loaded in batches
      source_client_personal_ids
      @enrollments_by_personal_id = nil # depends on source_client_personal_ids
      @enrollments_by_personal_id_with_deleted = nil # depends on source_client_personal_ids
      @exits_by_personal_id_and_entry_id = nil # depends on source_client_personal_ids
      @services_personal_id_and_entry_id = nil # depends on source_client_personal_ids
      @services_personal_id = nil # depends on source_client_personal_ids
      @personal_id_of_head_of_household_by_entry_id = nil # depends on enrollments_by_personal_id
      @projects_by_project_id = nil # depends on enrollments_by_personal_id
      @most_recent_day_project_for_clients = nil
      @enrollments_by_project_entry_id = nil # depends on enrollments_by_personal_id
    end

    # Fetch any warehouse_clients_processed_source who don't have an entry in destination_client_scope
    #   Delete their service history
    def remove_stale_history
      logger.info "Looking for histories for clients we no longer have..."
      missing_clients = warehouse_clients_processed_source.select(:client_id).where.not(client: destination_client_scope).pluck(:client_id)
      logger.info "...found #{missing_clients.size}"

      logger.info "Looking for partial histories or clients who've been invalidated..."
      service_history_clients = service_history_source.distinct.select(:client_id).pluck(:client_id)
      processed_clients = warehouse_clients_processed_source.service_history.select(:client_id).pluck(:client_id)
      clients_with_missing_process_history = service_history_clients - processed_clients
      logger.info "...found #{clients_with_missing_process_history.size}"

      @to_delete = (missing_clients + clients_with_missing_process_history).uniq
      if @to_delete.size == 0
        logger.info "Nothing to delete."
      elsif @dry_run
        logger.info "Would have deleted service history for #{@to_delete.size} clients."
      else
        logger.info "Deleting service history for #{@to_delete.size} clients..."
        deleted = 0
        @to_delete.each_slice(100) do |delete_me|
          service_history_source.where(client_id: delete_me).delete_all
          warehouse_clients_processed_source.where(client_id: delete_me).delete_all
          deleted += delete_me.size
          status('Delete', deleted, denominatar: @to_delete.size)
        end
        logger.info "...deleted #{deleted}."
      end
    end

    def build_history
      raise 'Define in subclass'
    end


    # This is going to be nasty:
    # 1. Figure out what's changed:
    #   Find Enrollment, Service & Exit records that have changed since last time
    #   Delete any Enrollments, Service events and Exits that no longer are relevant
    # 2. Build out the entire client history so we have correct metadata, then filter and
    #   Rebuild any Enrollments that contain changed Services and Exits

    def update id
      # load client metadata
      @client = clients_by_id[id]
      # materialized entries for this client
      entries = []

      services = services_for_client_id(id)
      services_to_update = services.select do |service|
        # Don't ask, but we've seen services with no dates
        service[:updated_at].present? && service[:updated_at] > @to_update[id] && service[:deleted_at].blank?
      end
      services_to_delete = services.select do |service|
        service[:deleted_at].present? && service[:deleted_at] > @to_update[id]
      end

      exits = exits_for_client_id(id)
      exits_to_update = exits.select do |e|
        e[:updated_at] > @to_update[id] && e[:deleted_at].blank?
      end
      exits_to_delete = exits.select do |e|
        e[:deleted_at].present? && e[:deleted_at] > @to_update[id]
      end
   
      enrollments = find_enrollments_with_deleted(id)
      # Find any changed enrollments
      simple_services = services_to_update.map do |service| 
        [service[:entry_id], service[:data_source_id]]
      end
      simple_exits = exits_to_update.map do |e| 
        [e[:entry_id], e[:data_source_id]]
      end
      enrollments_to_update = enrollments.select do |enrollment|
        lookup = [
          enrollment[:entry_id],
          enrollment[:data_source_id]
        ]
        enrollment[:updated_at] > @to_update[id] &&
        enrollment[:deleted_at].blank? ||
        # Include any for which we've flagged a service or exit rebuild as well
        simple_services.include?(lookup) ||
        simple_exits.include?(lookup)
      end

      enrollments_to_delete = enrollments.select do |enrollment|
        enrollment[:deleted_at].present? && enrollment[:deleted_at] > @to_update[id]
      end

      # Sometimes the change has come from somewhere else that triggered the rebuild.
      # We only care if we've changed the client table, if we have, we'll add them 
      # to @to_add and let it rebuild (maybe we have a new birthday)
      if (enrollments_to_update + enrollments_to_delete + services_to_delete + exits_to_delete).empty?
        source_clients_for(id).each do |client_id|
          if clients_by_id[client_id][:updated_at] > @to_update[id]
            # logger.info "Originally updating #{id}, now adding"
            @to_add << id
            return
          else
            # some other random table was updated, we don't need to do anything
            logger.info "No changes found for #{id}, fixing so we don't see them again until they change"
            processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
            processed.routine = 'service_history'
            processed.last_service_updated_at = max_date_updated_for_destination_id(id)
            processed.save unless @dry_run
            return
            return
          end
        end
      end
      
      # Delete all serviced history records associated with enrollments_to_delete
      logger.info "Deleting #{enrollments_to_delete.size} enrollments for #{id}" if enrollments_to_delete.any?
      enrollments_to_delete.each do |enrollment|
        project_id = enrollment[:project_id]
        enrollment_group_id = enrollment[:entry_id]
        data_source_id = enrollment[:data_source_id]
        service_history_source.where(
          client_id: id, 
          project_id: project_id, 
          enrollment_group_id: enrollment_group_id, 
          data_source_id: data_source_id
        ).delete_all
        # remove any associated services and exits we were planning on deleting or updating
        services_to_update.delete_if do |s| 
          s[:entry_id] == enrollment_group_id && s[:data_source_id] == data_source_id 
        end
        services_to_delete.delete_if do |s| 
          s[:entry_id] == enrollment_group_id && s[:data_source_id] == data_source_id 
        end
        exits_to_update.delete_if do |e| 
          e[:entry_id] == enrollment_group_id && e[:data_source_id] == data_source_id 
        end
        exits_to_delete.delete_if do |e| 
          e[:entry_id] == enrollment_group_id && e[:data_source_id] == data_source_id 
        end
      end

      # Delete any remaining Services and Exits marked for deletion
      logger.info "Deleting #{services_to_delete.size} services for #{id}" if services_to_delete.any?
      services_to_delete.each do |service|
        date = service[:date]
        enrollment_group_id = service[:entry_id]
        data_source_id = service[:data_source_id]
        service_history_source.where(
          date: date,
          client_id: id,
          enrollment_group_id: enrollment_group_id,
          data_source_id: data_source_id,
          record_type: 'service'
        ).delete_all
      end
      logger.info "Deleting #{exits_to_delete.size} exits for #{id}" if exits_to_delete.any?
      exits_to_delete.each do |e|
        enrollment_group_id = e[:entry_id]
        data_source_id = e[:data_source_id]
        service_history_source.where(
          client_id: id, 
          enrollment_group_id: enrollment_group_id, 
          data_source_id: data_source_id, 
          record_type: 'exit'
        ).delete_all
      end
  
      # Rebuild (in RAM only) all enrollments so we have correct metadata
      enrollments.each do |e|
        entries += build_entries(e)
      end
      if entries.empty?
        # If we didn't find anything that needs updating, just make a note that we've 
        # checked up until the new date
        processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
        processed.routine = 'service_history'
        processed.last_service_updated_at = max_date_updated_for_destination_id(id)
        processed.save unless @dry_run
        return
      end

      # Find client metadata
      service_entries = entries.select{|m| m[:record_type] == 'service'}
      days_served = 0
      first_date_served = entries.min_by{|m| m[:date]}[:date]
      last_date_served = entries.max_by{|m| m[:date]}[:date]
      entries_per_day = 0
      if service_entries.any?
        days_served = service_entries.map{|h| h[:date]}.uniq.size
        entries_per_day = entries.size.to_f/days_served
      end
      headers = entries.first.keys
      # Filter entries prior to actually sending them to the database to speed things up
      # and limit churn
      simple_enrollments = enrollments_to_update.map do |enrollment|
        [enrollment[:entry_id], enrollment[:data_source_id]]
      end
      entries_to_add = entries.select do |entry|
        simple_enrollments.include?([entry[:entry_id], entry[:data_source_id]])
      end.map(&:values)
      benchmark "   added #{entries_to_add.size} entries (#{entries_per_day.round(2)}/day) for client_id: #{id} #{first_date_served.iso8601}-#{last_date_served.iso8601}" do
        unless @dry_run
          # Save Service History
          # Delete any existing service history for any changed enrollments
          logger.info "Rebuilding #{enrollments_to_update.size} enrollments" if enrollments_to_update.any?
          enrollments_to_update.each do |enrollment|
            project_id = enrollment[:project_id]
            enrollment_group_id = enrollment[:entry_id]
            data_source_id = enrollment[:data_source_id]
            service_history_source.where(
              client_id: id, 
              project_id: project_id, 
              enrollment_group_id: enrollment_group_id, 
              data_source_id: data_source_id
            ).delete_all
          end

          insert_batch(service_history_source, headers, entries_to_add, transaction: false)
          # service_history_source.import headers, entries.map(&:values)
          processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
          processed.routine = 'service_history'
          processed.last_service_updated_at = max_date_updated_for_destination_id(id)
          processed.first_date_served = first_date_served
          processed.last_date_served = last_date_served
          processed.days_served = days_served
          processed.save
        end
      end
      @rows_inserted += entries_to_add.size
      @progress.progress += entries_to_add.size
    end

    def status(routine, index, commit_after: nil, denominatar: nil)
      # print '.' # one dot per client processed
      # $stdout.flush
      @progress.format = "#{@progress_format} clients_#{routine.downcase}:#{index}/#{denominatar} =="
      if commit_after && (index % commit_after == 0) && index != 0
        benchmark " sending db commit for last #{commit_after} clients" do
          GrdaWarehouseBase.connection.execute('COMMIT TRANSACTION; BEGIN TRANSACTION')
        end
      end
    end

    def patch id
      # load client metadata
      @client = clients_by_id[id]
      # grab most recent days for all open enrollments by project
      most_recent_day_by_project = most_recent_day_in_project_for_client(id)
      entries_to_add = []
      last_dates_served = []
      unique_days = Set.new
      # if we don't have any service history or source clients, ignore this one.
      return if most_recent_day_by_project.blank? || source_clients_for(id).empty?
      most_recent_day_by_project.each do |day|
        # Find the export associated with the source enrollment,
        # which may have a different (and updated) export_id than the 
        # most recent day 
        export = export_for_project_entry_id(
          data_source_id: day[:data_source_id], 
          project_entry_id: day[:enrollment_group_id]
        )
        # If we don't have a source enrollment, something went wrong
        # Queue run the add method, which will blow away their service history
        # and re-create it
        if export.blank?
          log_and_send_message "Client #{id} has enrollments in the service history that don't exist in the source data, rebuilding. day: #{day.inspect}"
          add(id)
          @sanity_check << id
          return
        end
        build_history_until = [Date.today, export[:end_date]].compact.min

        last_dates_served << build_history_until
        date = day[:date] + 1.days

        project = project(project_id: day[:project_id], data_source_id: day[:data_source_id])
        return unless project.present?
        
        if entry_exit_tracking(project)
          while date < build_history_until
            new_day = day.deep_dup
            unique_days << date
            new_day[:date] = date
            new_day[:age] = client_age_at(date)
            new_day[:record_type] = 'service' # force this
            entries_to_add << new_day
            date += 1.days
          end
        end
      end
      if entries_to_add.any?
        entries_per_day = entries_to_add.size.to_f/unique_days.size
        unless @dry_run
          benchmark "   patched #{entries_to_add.size} entries (#{entries_per_day.round(2)}/day) for client_id: #{id}" do
            insert_batch(
              service_history_source, 
              service_history_columns.values, 
              entries_to_add.map(&:values), 
              transaction: false
            )
            # update the last date served for this client
            last_date_served = last_dates_served.max
            processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
            processed.last_date_served = last_date_served
            if processed.days_served.blank?
              processed.days_served = unique_days.size
            else
              processed.days_served += unique_days.size
            end
            processed.save
          end
        end
        @rows_inserted += entries_to_add.size
      else
         # logger.info "   allset client_id: #{id}"
      end
    end

    def add id
      # load client metadata
      @client = clients_by_id[id]
      # materialized entries for this client
      entries = []
      # Generate new Service History
      enrollments = find_enrollments(id)
      enrollments.each do |e|
        entries += build_entries(e)
      end
      if entries.empty?
        # Mark the client processed, so we don't try to process them again and again even though they don't have any enrollments
        processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
        processed.routine = 'service_history'
        # attempt to find the updated date, but if we don't have anything, we should
        # be safe using today
        processed.last_service_updated_at = max_date_updated_for_destination_id(id) || Date.today
        processed.first_date_served = nil
        processed.last_date_served = nil
        processed.days_served = 0
        processed.save unless @dry_run
        return
      end

      # Find client metadata
      service_entries = entries.select{|m| m[:record_type] == 'service'}
      days_served = 0
      first_date_served = entries.min_by{|m| m[:date]}[:date]
      last_date_served = entries.max_by{|m| m[:date]}[:date]
      entries_per_day = 0
      if service_entries.any?
        days_served = service_entries.map{|h| h[:date]}.uniq.size
        entries_per_day = entries.size.to_f/days_served
      end
      headers = entries.first.keys
      entries_to_add = entries.map(&:values)
      benchmark "   added #{entries_to_add.size} entries (#{entries_per_day.round(2)}/day) for client_id: #{id} #{first_date_served.iso8601}-#{last_date_served.iso8601}" do
        unless @dry_run
          # Save Service History
          # Delete any existing service history (moved to the individual client so we can have a more consistent GUI)
          service_history_source.where(client_id: id).delete_all
          insert_batch(service_history_source, headers, entries_to_add, transaction: false)
          # service_history_source.import headers, entries.map(&:values)
          processed = warehouse_clients_processed_source.where(client_id: id, routine: 'service_history').first_or_initialize
          processed.routine = 'service_history'
          processed.last_service_updated_at = max_date_updated_for_destination_id(id)
          processed.first_date_served = first_date_served
          processed.last_date_served = last_date_served
          processed.days_served = days_served
          processed.save
        end
      end
      @rows_inserted += entries_to_add.size
      @progress.progress += entries_to_add.size  
    end

    # DANGER: This pulls a super set of clients because it doesn't pluck data_source_id
    # PersonalID is NOT a unique key
    def source_client_personal_ids
      @source_client_personal_ids ||= [].tap do |m|
        all_ids = @batch
        all_ids.each_slice(5000) do |ids|
          m.concat(GrdaWarehouse::Hud::Client.joins(:warehouse_client_source).where(warehouse_clients: {destination_id: ids}).pluck(:PersonalID))
        end
      end
    end

    def clients_by_id
      @clients_by_id ||= begin
        GrdaWarehouse::Hud::Client.pluck(*client_columns.values).
          map do |row|
            Hash[client_columns.keys.zip(row)]
          end.
          index_by{ |row| row[:id]}
      end
    end

    def client_sources
      @client_sources ||= {}.tap do |m|
        # exclude clients who have been deleted
        GrdaWarehouse::WarehouseClient.joins(:source).pluck(:destination_id, :source_id).each do |row|
          m[row.first] ||= []
          m[row.first] << row.last
        end
      end
    end

    def source_clients_for destination
      return [] if client_sources[destination].blank?
      client_sources[destination]
    end

    def enrollments_by_personal_id
      @enrollments_by_personal_id ||= begin
        # Fetch Enrollments in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(
              GrdaWarehouse::Hud::Enrollment.where(PersonalID: ids).
                pluck(*enrollment_columns.values).
                map do |row|
                  Hash[enrollment_columns.keys.zip(row)]
                end 
            )
          end
        end.group_by do |row|
          [row[:personal_id], row[:data_source_id]]
        end
      end
    end

    # If the export_id
    def export_for_project_entry_id data_source_id:, project_entry_id:
      @enrollments_by_project_entry_id ||= begin
        enrollments_by_personal_id.values.flatten(1).index_by do |row|
          [row[:data_source_id], row[:entry_id]]
        end
      end
      # If we don't have a source enrollment, something went wrong
      # (Probably our who updated calculation was off)
      # so we'll queue them to rebuild via a sanity check 
      # and then return false
      if @enrollments_by_project_entry_id[[data_source_id, project_entry_id]].present?
        export_id = @enrollments_by_project_entry_id[[data_source_id, project_entry_id]][:export_id]
      else
        return false
      end
      export_for_export_id(data_source_id: data_source_id, export_id: export_id)
    end

    def enrollments_by_personal_id_with_deleted
      @enrollments_by_personal_id_with_deleted ||= begin
        # Fetch Enrollments in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(
              GrdaWarehouse::Hud::Enrollment.with_deleted.where(PersonalID: ids).
                pluck(*enrollment_columns.values).
                map do |row|
                  Hash[enrollment_columns.keys.zip(row)]
                end
            )
          end
        end.group_by do |row|
            [row[:personal_id], row[:data_source_id]]
        end
      end
    end

    def personal_id_of_head_of_household_by_entry_id(entry)
      lookup  = [entry[:entry_id], entry[:data_source_id]]
      @personal_id_of_head_of_household_by_entry_id ||= begin
        {}.tap do |m|
          enrollments_by_personal_id.values.flatten(1).each do |entry|
            key = [entry[:entry_id], entry[:data_source_id]]
            if entry[:relationship_to_hoh].blank? || entry[:relationship_to_hoh] == 1 # 1 = Self HUD#relationship_to_hoh
              m[key] = entry[:personal_id]
            end
          end
        end
      end
      @personal_id_of_head_of_household_by_entry_id[lookup]
    end

    def most_recent_day_in_project_for_client client_id
      @most_recent_day_project_for_clients ||= begin
        services = service_history_source
        st = services.arel_table
        subtable = services.
          select(
            st[:date].maximum.as('date'),
            st[:project_id],
            st[:data_source_id],
            st[:client_id]
          ).
          where( st[:record_type].eq('service')).
          where( client_id: @batch, last_date_in_program: nil ).
          group( :project_id, :data_source_id, :client_id ).
          as('sh')
        stt = Arel::Table.new 'sh'
        join_condition = st[:client_id].eq(stt[:client_id]).
          and( st[:project_id].eq stt[:project_id] ).
          and( st[:date].eq stt[:date] ).
          and( st[:data_source_id].eq stt[:data_source_id] )
        results = services.
          joins("INNER JOIN #{subtable.to_sql} ON #{join_condition.to_sql}").
          pluck(*service_history_columns.values)
        results.map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.group_by do |row|
          row[:client_id]
        end
      end
      @most_recent_day_project_for_clients[client_id]
    end

    def exits_by_personal_id_and_entry_id enrollment
      lookup = [
        enrollment[:personal_id], 
        enrollment[:data_source_id],
        enrollment[:entry_id]
      ]
      @exits_by_personal_id_and_entry_id ||= begin
        # Fetch Exits in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(
              GrdaWarehouse::Hud::Exit.where(PersonalID: ids).
              pluck(*exit_columns.values).
              map do |row|
                Hash[exit_columns.keys.zip(row)]
              end
            )
          end
        end.index_by do |row|
          [
            row[:personal_id], 
            row[:data_source_id],
            row[:entry_id]
          ]
        end
      end
      @exits_by_personal_id_and_entry_id[lookup]
    end

    def exits_for_personal_id personal_id:, data_source_id:
      lookup = [personal_id, data_source_id]
      @exits_by_personal_id ||= begin
        # Fetch Exits in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(
              GrdaWarehouse::Hud::Exit.with_deleted.where(PersonalID: ids).
                pluck(*exit_columns.values).
                map do |row|
                  Hash[exit_columns.keys.zip(row)]
                end
            )
          end
        end.group_by do |row|
          [row[:personal_id], row[:data_source_id]]
        end
      end
      @exits_by_personal_id[lookup]
    end

    def exits_for_client_id destination_id
      source_clients_for(destination_id).map do |id|
        exits_for_personal_id(
          personal_id: field_for_client(client_id: id, field: :personal_id), 
          data_source_id: field_for_client(client_id: id, field: :data_source_id)
        )
      end.compact.flatten(1)
    end

    def field_for_client client_id:, field:
      clients_by_id[client_id][field]
    end
    
    def export_for_export_id data_source_id:, export_id:
      @exports_by_export_id ||= begin
        # Find the export
        GrdaWarehouse::Hud::Export
          .order(ExportDate: :asc, ExportEndDate: :asc)
          .pluck(*export_columns.values)
          .map do |row|
            Hash[export_columns.keys.zip(row)]
          end
          .index_by do |row| 
            [row[:data_source_id], row[:export_id]]
          end
      end
      @exports_by_export_id[[data_source_id, export_id]]
    end

    def services_personal_id_and_entry_id project_id, entry_id, data_source_id
      lookup = [project_id, entry_id, data_source_id]
      @services_personal_id_and_entry_id ||= begin
        columns = service_columns.dup
        columns[:project_id] = p_t[:ProjectID].as('project_id').to_sql
        # Fetch Exits in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(GrdaWarehouse::Hud::Service.joins(:project).
              where(PersonalID: ids).
              pluck(*columns.values).
              map do |row|
                Hash[columns.keys.zip(row)]
              end
            )
          end
        end.group_by do |row|
          [
            row[:project_id], 
            row[:data_source_id], 
            row[:entry_id]
          ]
        end
      end
      @services_personal_id_and_entry_id[lookup]
    end

    def services_for_personal_id personal_id, data_source_id
      lookup = [personal_id, data_source_id]
      @services_personal_id ||= begin
        # Fetch Exits in batches
        [].tap do |m|
          source_client_personal_ids.each_slice(5000) do |ids|
            m.concat(
              GrdaWarehouse::Hud::Service.with_deleted.where(PersonalID: ids).
              pluck(*service_columns.values).
              map do |row|
                Hash[service_columns.keys.zip(row)]
              end
            )
          end
        end.group_by do |row|
          [row[:personal_id], row[:data_source_id]]
        end
      end
      @services_personal_id[lookup]
    end

    def services_for_client_id destination_id
      source_clients_for(destination_id).map do |s|
        services_for_personal_id(
          field_for_client(client_id: id, field: :personal_id), 
          field_for_client(client_id: id, field: :data_source_id)
        )
      end.compact.flatten(1)
    end

    def project project_id:, data_source_id:
      raise 'Missing ProjectID' unless project_id.present? && data_source_id.present?
      @projects_by_project_id ||= begin
        enrollments_by_personal_id.values.flatten(1).group_by do |row|
          row[:data_source_id]
        end.
        map do |ds_id, enrollment_group|
          GrdaWarehouse::Hud::Project.where(data_source_id: ds_id).
            where(ProjectID: enrollment_group.map{|enrollment| enrollment[:project_id]}).
            pluck(*project_columns.values).
            map do |row|
              Hash[project_columns.keys.zip(row)]
            end
        end.
        flatten(1).index_by do |row|
          [row[:project_id], row[:data_source_id]] 
        end
      end
      @projects_by_project_id[[project_id, data_source_id]]
    end

    def max_update_for_export(export: )
      lookup = [export[:export_id], export[:data_source_id]]
      @max_updates_for_export_ids ||= begin
        services =  GrdaWarehouse::Hud::Service.group(:ExportID, :data_source_id).maximum(:DateUpdated)
        enrollments = GrdaWarehouse::Hud::Enrollment.group(:ExportID, :data_source_id).maximum(:DateUpdated)
        clients = GrdaWarehouse::Hud::Client.group(:ExportID, :data_source_id).maximum(:DateUpdated)
        exits =  GrdaWarehouse::Hud::Exit.group(:ExportID, :data_source_id).maximum(:DateUpdated)
        maxes = services.merge(services).merge(enrollments) do |_, old, new| 
          [old,new].max
        end.merge(enrollments) do |_, old, new| 
          [old,new].max
        end.merge(clients) do |_, old, new| 
          [old,new].max
        end.merge(exits) do |_, old, new| 
          [old,new].max
        end
      end
      @max_updates_for_export_ids[lookup]
    end

    def max_date_updated_personal_id
      @max_date_updated_personal_id ||= begin
        logger.info 'Looking up max updated dates for all clients.'
        {}.tap do |res|

          # we want to generate this (here for documentation purposes)
          
          sql = <<-SQL
            SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM (
              SELECT data_source_id, PersonalId, MAX(DateUpdated) as DateUpdated, MAX(DateDeleted) as DateDeleted FROM [Client], [data_sources]
                WHERE [Client].data_source_id = [data_sources].id
                  and [data_sources].source_type is NOT NULL
                 GROUP BY data_source_id, PersonalId
              UNION
              -- SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [Disabilities] GROUP BY data_source_id, PersonalId
              -- UNION
              -- SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [EmploymentEducation] GROUP BY data_source_id, PersonalId
              -- UNION
              SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [Enrollment] GROUP BY data_source_id, PersonalId
              UNION
              -- SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [EnrollmentCoC] GROUP BY data_source_id, PersonalId
              -- UNION
              SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [Exit] GROUP BY data_source_id, PersonalId
              UNION
              -- SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [HealthAndDV] GROUP BY data_source_id, PersonalId
              -- UNION
              -- SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [IncomeBenefits] GROUP BY data_source_id, PersonalId
              -- UNION
              SELECT data_source_id, PersonalId, MAX(DateUpdated), MAX(DateDeleted) FROM [Services] GROUP BY data_source_id, PersonalId
            ) a GROUP BY data_source_id, PersonalId
          SQL

          # but we need it to be DBMS-agnostic, so we do this

          ct = GrdaWarehouse::Hud::Client.arel_table
          dt = GrdaWarehouse::DataSource.arel_table

          # make some tables to joined via union
          t = unionize [
            [
              ct,
              ct.join(dt).on( ct[:data_source_id].eq dt[:id] ).where( dt[:source_type].not_eq nil )
            ],
            [GrdaWarehouse::Hud::Enrollment.arel_table],
            [GrdaWarehouse::Hud::Exit.arel_table],
            [GrdaWarehouse::Hud::Service.arel_table]
          ].map do |t, base=t|
            base.project(
                t[:PersonalID].as('PersonalID'),
                t[:data_source_id].as('data_source_id'),
                t[:DateUpdated].maximum.as('DateUpdated'),
                t[:DateDeleted].maximum.as('DateDeleted')
              ).
              group( t[:PersonalID], t[:data_source_id] )
          end
          t = add_alias :a, t

          # construct the query
          query = ct.engine.with_deleted.select(   # note that *any* arel table engine will do; we add the with_deleted scope to prevent paranoia shenanigans with this table
              t[:data_source_id],
              t[:PersonalID],
              t[:DateUpdated].maximum,
              t[:DateDeleted].maximum
            ).from(t).group( t[:PersonalID], t[:data_source_id] )

          sql = query.to_sql
          if GrdaWarehouseBase.postgres?
            sql = sql.gsub(/(?<= AS )\w+/){ |m| %Q("#{m}") }   # Arel doesn't get it quite right; quote aliases
          end

          GrdaWarehouse::Hud::Base.connection.select_rows(sql).map do |ds_id, personal_id, max_updated, max_deleted|
            # Fix the column type, select_rows now returns all strings
            ds_id = GrdaWarehouse::ServiceHistory.column_types['data_source_id'].type_cast_from_database(ds_id)
            max_updated = GrdaWarehouse::Hud::Service.column_types['DateUpdated'].type_cast_from_database(max_updated)
            max_deleted = GrdaWarehouse::Hud::Service.column_types['DateDeleted'].type_cast_from_database(max_deleted)
            res[[personal_id, ds_id]] = ActiveSupport::TimeWithZone.new([max_updated, max_deleted].compact.max, Time.zone)
          end
        end
      end
    end

    def client_columns
      {
        personal_id: c_t[:PersonalID].as('personal_id').to_sql,
        data_source_id: c_t[:data_source_id].as('data_source_id').to_sql,
        dob: c_t[:DOB].as('DOB').to_sql,
        updated_at: c_t[:DateUpdated].as('DateUpdated').to_sql,
        id: c_t[:id].as('id').to_sql,
      }
    end

    def enrollment_columns
      {
        entry_id: e_t[:ProjectEntryID].as('ProjectEntryID').to_sql,
        personal_id: e_t[:PersonalID].as('PersonalID').to_sql,
        project_id: e_t[:ProjectID].as('ProjectID').to_sql,
        entry_date: e_t[:EntryDate].as('EntryDate').to_sql,
        household_id: e_t[:HouseholdID].as('HouseholdID').to_sql,
        relationship_to_hoh: e_t[:RelationshipToHoH].as('RelationshipToHoH').to_sql,
        housing_status_at_entry: e_t[:HousingStatus].as('HousingStatus').to_sql,
        created_at: e_t[:DateCreated].as('DateCreated').to_sql,
        updated_at: e_t[:DateUpdated].as('DateUpdated').to_sql,
        deleted_at: e_t[:DateDeleted].as('DateDeleted').to_sql,
        export_id: e_t[:ExportID].as('ExportID').to_sql,
        id: e_t[:id].as('id').to_sql,
        data_source_id: e_t[:data_source_id].as('data_source_id').to_sql,
      }
    end

    def exit_columns
      {
        entry_id: exi_t[:ProjectEntryID].as('ProjectEntryID').to_sql,
        personal_id: exi_t[:PersonalID].as('PersonalID').to_sql,
        exit_date: exi_t[:ExitDate].as('ExitDate').to_sql,
        destination: exi_t[:Destination].as('Destination').to_sql,
        housing_status_at_exit: exi_t[:HousingAssessment].as('HousingAssessment').to_sql,
        created_at: exi_t[:DateCreated].as('DateCreated').to_sql,
        updated_at: exi_t[:DateUpdated].as('DateUpdated').to_sql,
        deleted_at: exi_t[:DateDeleted].as('DateDeleted').to_sql,
        id: exi_t[:id].as('id').to_sql,
        data_source_id: exi_t[:data_source_id].as('data_source_id').to_sql,
      }
    end

    def export_columns
      {
        export_id: exp_t[:ExportID].as('ExportID').to_sql,
        export_date: exp_t[:ExportDate].as('ExportDate').to_sql,
        export_end_date: exp_t[:ExportEndDate].as('ExportEndDate').to_sql,
        id: exp_t[:id].as('id').to_sql,
        data_source_id: exp_t[:data_source_id].as('data_source_id').to_sql,
      }
    end

    def service_columns
      {
        entry_id: s_t[:ProjectEntryID].as('ProjectEntryID').to_sql,
        personal_id: s_t[:PersonalID].as('PersonalID').to_sql,
        date: s_t[:DateProvided].as('DateProvided').to_sql,
        record_type: s_t[:RecordType].as('RecordType').to_sql,
        type_provided: s_t[:TypeProvided].as('TypeProvided').to_sql,
        created_at: s_t[:DateCreated].as('DateCreated').to_sql,
        updated_at: s_t[:DateUpdated].as('DateUpdated').to_sql,
        deleted_at: s_t[:DateDeleted].as('DateDeleted').to_sql,
        id: s_t[:id].as('id').to_sql,
        data_source_id: s_t[:data_source_id].as('data_source_id').to_sql,
      }
    end

    def project_columns
      {
        project_id: p_t[:ProjectID].as('ProjectID').to_sql,
        organization_id: p_t[:OrganizationID].as('OrganizationID').to_sql,
        project_type: p_t[:ProjectType].as('ProjectType').to_sql,
        project_name: p_t[:ProjectName].as('ProjectName').to_sql,
        project_tracking_method: p_t[:TrackingMethod].as('TrackingMethod').to_sql,
        data_source_id: p_t[:data_source_id].as('data_source_id').to_sql,
        id: p_t[:id].as('id').to_sql,
      }
    end

    def service_history_columns
      {
        client_id: :client_id,
        date: :date,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        enrollment_group_id: :enrollment_group_id,
        service_type: :service_type,
        project_type: :project_type,
        project_id: :project_id,
        age: :age,
        destination: :destination,
        head_of_household_id: :head_of_household_id,
        household_id: :household_id,
        project_name: :project_name,
        project_tracking_method: :project_tracking_method,
        record_type: :record_type,
        housing_status_at_entry: :housing_status_at_entry,
        housing_status_at_exit: :housing_status_at_exit,
        data_source_id: :data_source_id,
        organization_id: :organization_id,
      }
    end

    def find_enrollments destination
      return [] if source_clients_for(destination).empty?
      source_clients_for(destination).map do |id|
        enrollments_for_client(
          personal_id: field_for_client(client_id: id, field: :personal_id), 
          data_source_id: field_for_client(client_id: id, field: :data_source_id)
        )
      end.flatten(1).compact
    end
    
    def find_enrollments_with_deleted destination
      return [] if source_clients_for(destination).blank?
      source_clients_for(destination).map do |id|
        enrollments_for_client_with_deleted(
          personal_id: field_for_client(client_id: id, field: :personal_id), 
          data_source_id: field_for_client(client_id: id, field: :data_source_id)
        )
      end.flatten(1).compact
    end

    def enrollments_for_client personal_id:, data_source_id:
      enrollments_by_personal_id[[personal_id, data_source_id]]
    end

    def enrollments_for_client_with_deleted personal_id: , data_source_id:
      enrollments_by_personal_id_with_deleted[[personal_id, data_source_id]]
    end

    def entry_exit_tracking project
      ! street_outreach_acts_as_bednight?(project) && project[:project_tracking_method] != 3
    end

    # Some Street outreach are counted like bed-night shelters, others aren't yet
    def street_outreach_acts_as_bednight? project
      return false unless project.present?
      @bednight_so_projects ||= begin
        GrdaWarehouse::Hud::Project.so
          .joins(:services)
          .select(:ProjectID, :data_source_id)
          .where(Services: {RecordType: 12})
          .distinct
          .pluck(:ProjectID, :data_source_id)
      end
      @bednight_so_projects.include?([project[:project_id], project[:data_source_id]])
    end


    # Fetch exit
    # Fetch TrackingMethod
    # unless client is head of household
    #   fetch head of household (personal_id_of_head_of_household_by_entry_id[entry_id, data_source_id])
    # else
    #   head of household is self[PersonalID]
    # If entry/exit
    #   build records for all nights between entry and exit including entry, excluding exit
    # If bed-night
    #   fetch service entries
    #   build bed-night records
    #
    def build_entries enrollment
      # Changing and now building until the most-recent end date for the data source
      # This makes the assumption that we always have a complete data dump
      # per data source
      begin
        export = export_for_export_id(
          data_source_id: enrollment[:data_source_id], 
          export_id: enrollment[:export_id]
        )
        export_date = export[:export_date].to_date
        export_end = export[:export_end_date].to_date
      rescue Exception => e
        Rails.logger.error e.inspect
        Rails.logger.error enrollment.inspect
        log_and_send_message "Failed to build entries for client with enrollment: #{enrollment.inspect} and export: #{export.inspect}"
        return []
      end
      # Special case which comes up mostly with ETO exports where they fail to update the ExportDate
      build_history_until = if export_date.present? && export_end.present? && export_date < Date.today && Date.today < export_end
        max_update_for_export(export: export).to_date
      else
        [Date.today, export_date, export_end].compact.min
      end

      head_of_household_id = personal_id_of_head_of_household_by_entry_id(enrollment)
      program_exit = exits_by_personal_id_and_entry_id(enrollment)

      # If we have an exit date, use it
      if program_exit.present? && program_exit[:exit_date].present?
        build_history_until = program_exit[:exit_date]
      end
      # logger.info "Building entries until"
      # logger.info build_history_until
      project = project(
        project_id: enrollment[:project_id], 
        data_source_id: enrollment[:data_source_id]
      )
      # Some projects no longer exist, ignore them
      return [] unless project.present?
      if entry_exit_tracking(project)
        construct_history_by_entry_exit(enrollment: enrollment, program_exit: program_exit, head_of_household_id: head_of_household_id, project: project, build_history_until: build_history_until)
      else
        construct_history_by_service(enrollment: enrollment, program_exit: program_exit, head_of_household_id: head_of_household_id, project: project)
      end
    end

    # def discover_head_of_household_personal_id enrollment
    #   relationship_to_hoh_index = enrollment_relationship_to_hoh_index()
    #   personal_id_index = enrollment_personal_id_index()
    #   entry_id_index = enrollment_entry_id_index()
    #   data_source_id_index = enrollment_data_source_id_index()

    #   personal_id_of_head_of_household_by_entry_id[[enrollment[entry_id_index], enrollment[data_source_id_index]]]

    # end

    def construct_history_by_entry_exit enrollment:, program_exit:, head_of_household_id:, project:, build_history_until:
      program_exit_date = program_exit[:exit_date] if program_exit.present?
      program_destination = program_exit[:destination] if program_exit.present?
      housing_status_at_exit = program_exit[:housing_status_at_exit] if program_exit.present?
      program_entry_date = enrollment[:entry_date]
      project_type = project[:project_type]

      default_day = {
        client_id: @client[:id],
        date: nil,
        first_date_in_program: program_entry_date,
        last_date_in_program: program_exit_date,
        enrollment_group_id: enrollment[:entry_id],
        service_type: service_type_from_project_type(project_type),
        project_type: project_type,
        project_id: enrollment[:project_id],
        data_source_id: enrollment[:data_source_id],
        age: nil,
        destination: program_destination,
        head_of_household_id: head_of_household_id,
        household_id: enrollment[:household_id],
        project_name: project[:project_name],
        organization_id: project[:organization_id],
        project_tracking_method: project[:project_tracking_method],
        record_type: nil,
        housing_status_at_entry: enrollment[:housing_status_at_entry],
        housing_status_at_exit: housing_status_at_exit,
      }
      [].tap do |e|
        # Add an entry record
        day = default_day.merge({
          date: program_entry_date,
          age: client_age_at(program_entry_date),
          record_type: 'entry',
        })
        e << day

        # Build service entries for every day within the enrollment
        stay_length = (build_history_until - program_entry_date).to_i
        logger.info "Building #{stay_length} entries for #{default_day[:project_name]}"
        stay_length.times do |i|
          date = program_entry_date + i.days
          day = default_day.merge({
            date: date,
            age: client_age_at(date),
            record_type: 'service',
          })
          e << day
        end
        # Add an exit record
        if program_exit.present?
          day = default_day.merge({
            date: program_exit_date,
            age: client_age_at(program_exit_date),
            record_type: 'exit',
          })
          e << day
        end
      end
    end

    def construct_history_by_service enrollment:, program_exit:, head_of_household_id:, project:
      program_exit_date = program_exit[:exit_date] if program_exit.present?
      program_destination = program_exit[:destination] if program_exit.present?
      housing_status_at_exit = program_exit[:housing_status_at_exit] if program_exit.present?
      program_entry_date = enrollment[:entry_date]
      personal_id = enrollment[:personal_id]
      data_source_id = enrollment[:data_source_id]
      entry_id = enrollment[:entry_id]
      project_type = project[:project_type]
      project_id = project[:project_id]

      services = services_personal_id_and_entry_id(project_id, data_source_id, entry_id)

      default_day = {
        client_id: @client[:id],
        date: nil,
        first_date_in_program: program_entry_date,
        last_date_in_program: program_exit_date,
        enrollment_group_id: entry_id,
        service_type: service_type_from_project_type(project_type),
        project_type: project_type,
        project_id: enrollment[:project_id],
        data_source_id: enrollment[:data_source_id],
        age: nil,
        destination: program_destination,
        head_of_household_id: head_of_household_id,
        household_id: enrollment[:household_id],
        project_name: project[:project_name],
        organization_id: project[:organization_id],
        project_tracking_method: project[:project_tracking_method],
        record_type: nil,
        housing_status_at_entry: enrollment[:housing_status_at_entry],
        housing_status_at_exit: housing_status_at_exit,
      }
      [].tap do |e|
        # Add an entry record
        day = default_day.merge({
          date: program_entry_date,
          age: client_age_at(program_entry_date),
          record_type: 'entry',
        })
        e << day

        if services.present?
          # Add service records
          services.each do |s|
            date = s[:date]
            # There are some non-housing related services with no date provided
            # Just ignore them
            if date.present?
              day = default_day.merge({
                date: date,
                age: client_age_at(date),
                service_type: s[:type_provided],
                record_type: 'service',
              })
              e << day
            end
          end
        end

        # Add an exit record
        if program_exit.present?
          day = default_day.merge({
            date: program_exit_date,
            age: client_age_at(program_exit_date),
            record_type: 'exit',
          })
          e << day
        end
      end
    end

    def client_age_at date
      return unless @client[:dob].present? && date.present?
      dob = @client[:dob].to_date
      age = date.to_date.year - dob.year
      age -= 1 if dob > date.to_date.years_ago( age )
      # You have to be explicit here -= does not return age
      return age
    end

    def service_type_from_project_type project_type
      # ProjectType
      # 1 Emergency Shelter
      # 2 Transitional Housing
      # 3 PH - Permanent Supportive Housing
      # 4 Street Outreach
      # 6 Services Only
      # 7 Other
      # 8 Safe Haven
      # 9 PH – Housing Only
      # 10  PH – Housing with Services (no disability required for entry)
      # 11  Day Shelter
      # 12  Homelessness Prevention
      # 13  PH - Rapid Re-Housing
      # 14  Coordinated Assessment

      # RecordType
      # 12  Contact   4.12
      # 141 PATH service  4.14 A
      # 142 RHY service   4.14 B
      # 143 HOPWA service   4.14 C
      # 144 SSVF service    4.14 D
      # 151 HOPWA financial assistance  4.15 A
      # 152 SSVF financial assistance   4.15 B
      # 161 Path referral     4.16 A
      # 162 RHY referral  4.16 B
      # 200 Bed night   (none)

      # We will infer a bed night if the project type is housing related, everything else is nil for now
      housing_related = [1,2,3,4,8,9,10,13]
      return 200 if housing_related.include?(project_type)
      nil
    end

    def max_date_updated_for_destination_id destination_id
      # This shouldn't happen, but sometimes it gets confused
      return nil unless source_clients_for(destination_id).any?
      source_clients_for(destination_id).map do |id|
        lookup = [
          clients_by_id[id][:personal_id], 
          clients_by_id[id][:data_source_id]
        ]
        max_date_updated_personal_id[lookup]
      end.compact.max
    end

    # def load_history client_id
    #   service_history_source.where(client_id: client_id).
    #     pluck(*service_history_columns.values).
    #     map do |row|
    #       Hash[service_history_columns.keys.zip(row)]
    #     end
    # end

    def sh_t 
      service_history_source.arel_table
    end

    def c_t
      client_source.arel_table
    end

    def exi_t
      GrdaWarehouse::Hud::Exit.arel_table
    end

    def exp_t
      GrdaWarehouse::Hud::Export.arel_table
    end

    def p_t
      GrdaWarehouse::Hud::Project.arel_table
    end

    def s_t
      GrdaWarehouse::Hud::Service.arel_table
    end

    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end

    def d_t
      GrdaWarehouse::DataSource.arel_table
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def destination_client_scope
      client_source.destination
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def warehouse_clients_processed_source
      GrdaWarehouse::WarehouseClientsProcessed
    end
  end
end
