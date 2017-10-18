module GrdaWarehouse::Tasks::ServiceHistory
  class Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    include ArelHelper
    include NotifierConfig
    require 'ruby-progressbar'
    require 'parallel'
    attr_accessor :logger, :send_notifications, :notifier_config

    # Debugging
    attr_accessor :batch, :to_patch

    def initialize(client_ids: nil, dry_run: false)
      self.logger = Rails.logger
      setup_notifier('Service History Generator')
      @sanity_check = Set.new
      @batch_size = 1000

      @client_ids = client_ids
      @rows_inserted = 0
      @progress_format = '%a: service_history_days_generated:%c (%R/sec)'
      @progress = ProgressBar.create(starting_at: 0, total: nil, format: @progress_format)
      @pb_output_for_log = ProgressBar::Outputs::NonTty.new(bar: @progress)
      @dry_run = dry_run || ENV['DRY_RUN'].to_s.in?(['1','Y'])
    end

    def run!
      begin
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
        # When thins gets stuck, this is fun to read:
        # https://stackoverflow.com/questions/25213808/using-pgadmin-to-check-status-of-postgres-advisory-locks
        service_history_source.with_advisory_lock('service_history') do
          remove_stale_history()
          build_history()
        end

        sanity_check()
        
        completed_at = DateTime.now
        log.assign_attributes(completed_at: completed_at, to_delete: @to_delete.size, to_add: @to_add_count, to_update: @to_update_count)
        log.save unless @dry_run
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
      if @client_ids.present?
        logger.info "Using provided client list..."
        return @client_ids
      end
      logger.info "Finding clients needing updates..."
      clients = GrdaWarehouse::Hud::Client.destination.
        where.not(id: @to_add)
      parallel_style = if Rails.env.test?
        :in_threads
      else
        :in_processes
      end
      to_update = Parallel.map(clients, parallel_style => 4) do |client|
        valid = true
        client.source_enrollments.pluck(:id).map do |id|
          en = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(id)
          if valid && en.source_data_changed?
            valid = false
            client.id
          end
        end
      end
      # active record connections follow you into the child processes but don't return
      # so we'll explicitly disconnect and reconnect
      # https://github.com/grosser/parallel/issues/83
      begin
        GrdaWarehouseBase.connection.reconnect!
      rescue
        GrdaWarehouseBase.connection.reconnect!
      end
      to_update.flatten.compact
    end

    # Must be called after setting @to_update with clients_needing_updates()
    def clients_with_open_enrollments()
      # Finding any client with an open enrollment who just needs some days added
      logger.info "Finding existing clients with open enrollments (some will need days added)..."
      range = Filters::DateRange.new(start: 1.weeks.ago.to_date, end: Date.today)

      patch_scope = GrdaWarehouse::Hud::Enrollment.open_during_range(range).
        joins(:project, :destination_client).
        where.not(Project: {TrackingMethod: 3}).
        distinct
      if @to_update.any?
        patch_scope = patch_scope.where.not(Client: {id: @to_update})
      end
      if @to_add.any?
        patch_scope = patch_scope.where.not(Client: {id: @to_add})
      end
      to_patch = patch_scope.pluck(c_t[:id].as('client_id').to_sql)
      logger.info "...found #{to_patch.size}."
      to_patch
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

    def mark_processed client_id
      processed = warehouse_clients_processed_source.
        where(client_id: client_id, routine: :service_history).
        first_or_initialize
      processed.last_service_updated_at = Date.today
      processed.days_served = service_history_source.service.
        where(client_id: client_id).
        select(:date).
        distinct.
        count
      first_date_served = service_history_source.service.
        where(client_id: client_id).minimum(:date)
      last_date_served = service_history_source.service.
        where(client_id: client_id).maximum(:date)
      processed.save unless @dry_run
    end

    def process_to_update
      clients_completed = 0
      # prepare to sanity check anyone we've touched
      @sanity_check += @to_update
      # Process Updates
      log_and_send_message "Updating #{@to_update.size} clients in batches of #{@batch_size}"
      GC.start
      # Setup a huge transaction, we'll commit frequently
      GrdaWarehouseBase.transaction do
        @to_update.each_with_index do |id,index|
          enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
            joins(:source_enrollments).
            pluck(e_t[:id].as('enrollment_id').to_sql)
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
            enrollment.create_service_history!
          end
          mark_processed(id)
          clients_completed += 1
          status('Updated', clients_completed, commit_after: 10, denominator: @to_update.size)
        end
      end
      logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
      @progress.refresh
    end

    def process_to_add
      msg =  "Processing #{@to_add.size} new/invalidated clients in batches of #{@batch_size}"
      log_and_send_message msg

      GC.start
      # prepare to sanity check anyone we've touched
      @sanity_check += @to_add
      clients_completed = 0
      # Setup a huge transaction, we'll commit frequently
      GrdaWarehouseBase.transaction do
        @to_add.each_with_index do |id,index|
          enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
            joins(:source_enrollments).
            pluck(e_t[:id].as('enrollment_id').to_sql)
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
            enrollment.create_service_history!(true)
          end
          mark_processed(id)
          clients_completed += 1
          status('Added', clients_completed, commit_after: 10, denominator: @to_add.size)
        end
      end
      logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
      @progress.refresh
    end

    def process_to_patch
      log_and_send_message "Patching #{@to_patch.size} open enrollments..."
      @sanity_check += @to_patch
      clients_completed = 0
      # Setup a huge transaction, we'll commit frequently
      GrdaWarehouseBase.transaction do
        @to_patch.each_with_index do |id,index|
          clients_completed += 1
          enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
            joins(:source_enrollments).
            pluck(e_t[:id].as('enrollment_id').to_sql)
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
            enrollment.patch_service_history!
          end
          mark_processed(id)
          status('Patched', clients_completed, commit_after: 10, denominator: @to_patch.size)
        end
      end
      logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
      @progress.refresh
    end

    # Fetch any warehouse_clients_processed_source who don't have an entry in destination_client_scope
    #   Delete their service history
    def remove_stale_history
      logger.info "Looking for histories for clients we no longer have..."
      missing_clients = warehouse_clients_processed_source.select(:client_id).where.not(client: destination_client_scope).pluck(:client_id)
      logger.info "...found #{missing_clients.size}"

      logger.info "Looking for partial histories or clients who've been invalidated..."
      if @client_ids.present?
        service_history_clients = service_history_source.distinct.
        select(:client_id).where(client_id: @client_ids).
        pluck(:client_id)
      else
        service_history_clients = service_history_source.distinct.
          select(:client_id).pluck(:client_id)
      end
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
          status('Delete', deleted, denominator: @to_delete.size)
        end
        logger.info "...deleted #{deleted}."
      end
    end

    def build_history
      raise 'Define in subclass'
    end


   

    def status(routine, index, commit_after: nil, denominator: nil)
      # print '.' # one dot per client processed
      # $stdout.flush
      @progress.format = "#{@progress_format} clients_#{routine.downcase}:#{index}/#{denominator} =="
      if commit_after && (index % commit_after == 0) && index != 0
        benchmark " sending db commit for last #{commit_after} clients" do
          GrdaWarehouseBase.connection.execute('COMMIT TRANSACTION; BEGIN TRANSACTION')
        end
      end
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
