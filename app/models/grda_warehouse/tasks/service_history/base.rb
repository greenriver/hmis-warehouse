module GrdaWarehouse::Tasks::ServiceHistory
  class Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    include ArelHelper
    include NotifierConfig
    require 'ruby-progressbar'

    attr_accessor :logger, :send_notifications, :notifier_config

    # Debugging
    attr_accessor :batch, :to_patch

    def initialize(client_ids: nil, force_sequential_processing: false)
      self.logger = Rails.logger
      setup_notifier('Service History Generator')
      @batch_size = 250
      @client_ids = Array(client_ids)
      @force_sequential_processing = force_sequential_processing
    end

    def run!
      raise NotImplementedError
    end

    def process
      begin
        logger.info "Generating Service History #{'[DRY RUN!]' if @dry_run}"
        @client_ids = if @client_ids.any?
          @client_ids
        else
          destination_client_scope.pluck(:id)
        end
        batches = @client_ids.each_slice(@batch_size)
        started_at = DateTime.now
        log = GrdaWarehouse::GenerateServiceHistoryLog.create(started_at: started_at, batches: batches.size)
        batches.each do |batch|
          if @force_sequential_processing
            ::ServiceHistory::RebuildEnrollmentsJob.new(client_ids: batch, log_id: log.id).perform_now
          else
            job = Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsJob.new(client_ids: batch, log_id: log.id), queue: :service_history)

          end
        end
      ensure
        Rails.cache.delete('sanity_check_count')
      end
    end

    def self.wait_for_processing
      # you must manually process these in the test environment since there are no workers
      unless Rails.env.test?
        started = Time.now
        while Delayed::Job.where(queue: :service_history, failed_at: nil).count > 0 do
          break if ((Time.now - started) / 1.hours) > 12
          sleep(30)
        end
      end
    end

    # sanity check anyone we've touched
    def sanity_check
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(10_000).run!
      # batches = @sanity_check.each_slice(@batch_size)
      # batches.each_with_index do |batch, index|
      #   # log_and_send_message "Sanity Checking all #{@sanity_check.size} clients in batches of #{batch.size}.  Batch #{index + 1}"
      #   GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(1, batch).run!
      # end
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
      # The index gets in the way of calculating these quickly.  It is *much* faster
      # to simply bring back all of the dates and use ruby to get the correct one
      first_date_served = service_history_source.service.
        where(client_id: client_id).order(date: :desc).pluck(:date).last
      last_date_served = service_history_source.service.
        where(client_id: client_id).order(date: :desc).pluck(:date).first
      processed.save
      destination_client_scope.clear_view_cache(client_id)
    end

    # def process_to_update
    #   clients_completed = 0
    #   # prepare to sanity check anyone we've touched
    #   @sanity_check += @to_update
    #   # Process Updates
    #   log_and_send_message "Updating #{@to_update.size} clients in batches of #{@batch_size}"
    #   GC.start
    #   # Setup a huge transaction, we'll commit frequently
    #   GrdaWarehouseBase.transaction do
    #     @to_update.each_with_index do |id,index|
    #       enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
    #         joins(:source_enrollments).
    #         pluck(e_t[:id].as('enrollment_id').to_sql)
    #       GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
    #         enrollment.create_service_history!
    #       end
    #       mark_processed(id)
    #       clients_completed += 1
    #       status('Updated', clients_completed, commit_after: 10, denominator: @to_update.size)
    #     end
    #   end
    #   logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
    #   @progress.refresh
    # end

    # def process_to_add
    #   msg =  "Processing #{@to_add.size} new/invalidated clients in batches of #{@batch_size}"
    #   log_and_send_message msg

    #   GC.start
    #   # prepare to sanity check anyone we've touched
    #   @sanity_check += @to_add
    #   clients_completed = 0
    #   # Setup a huge transaction, we'll commit frequently
    #   GrdaWarehouseBase.transaction do
    #     @to_add.each_with_index do |id,index|
    #       enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
    #         joins(:source_enrollments).
    #         pluck(e_t[:id].as('enrollment_id').to_sql)
    #       GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
    #         enrollment.create_service_history!(true)
    #       end
    #       mark_processed(id)
    #       clients_completed += 1
    #       status('Added', clients_completed, commit_after: 10, denominator: @to_add.size)
    #     end
    #   end
    #   logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
    #   @progress.refresh
    # end

    # def process_to_patch
    #   log_and_send_message "Patching #{@to_patch.size} open enrollments..."
    #   @sanity_check += @to_patch
    #   clients_completed = 0
    #   # Setup a huge transaction, we'll commit frequently
    #   GrdaWarehouseBase.transaction do
    #     @to_patch.each_with_index do |id,index|
    #       clients_completed += 1
    #       enrollment_ids = GrdaWarehouse::Hud::Client.where(id: id).
    #         joins(:source_enrollments).
    #         pluck(e_t[:id].as('enrollment_id').to_sql)
    #       GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each do |enrollment|
    #         enrollment.patch_service_history!
    #       end
    #       mark_processed(id)
    #       status('Patched', clients_completed, commit_after: 10, denominator: @to_patch.size)
    #     end
    #   end
    #   logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
    #   @progress.refresh
    # end

    # # Fetch any warehouse_clients_processed_source who don't have an entry in destination_client_scope
    # #   Delete their service history
    # def remove_stale_history
    #   logger.info "Looking for histories for clients we no longer have..."
    #   missing_clients = warehouse_clients_processed_source.select(:client_id).where.not(client: destination_client_scope).pluck(:client_id)
    #   logger.info "...found #{missing_clients.size}"

    #   logger.info "Looking for partial histories or clients who've been invalidated..."
    #   if @client_ids.present?
    #     service_history_clients = service_history_source.distinct.
    #     select(:client_id).where(client_id: @client_ids).
    #     pluck(:client_id)
    #   else
    #     service_history_clients = service_history_source.distinct.
    #       select(:client_id).pluck(:client_id)
    #   end
    #   processed_clients = warehouse_clients_processed_source.service_history.select(:client_id).pluck(:client_id)
    #   clients_with_missing_process_history = service_history_clients - processed_clients
    #   logger.info "...found #{clients_with_missing_process_history.size}"

    #   @to_delete = (missing_clients + clients_with_missing_process_history).uniq
    #   if @to_delete.size == 0
    #     logger.info "Nothing to delete."
    #   elsif @dry_run
    #     logger.info "Would have deleted service history for #{@to_delete.size} clients."
    #   else
    #     logger.info "Deleting service history for #{@to_delete.size} clients..."
    #     deleted = 0
    #     @to_delete.each_slice(100) do |delete_me|
    #       service_history_source.where(client_id: delete_me).delete_all
    #       warehouse_clients_processed_source.where(client_id: delete_me).delete_all
    #       deleted += delete_me.size
    #       status('Delete', deleted, denominator: @to_delete.size)
    #     end
    #     logger.info "...deleted #{deleted}."
    #   end
    # end

    # def build_history
    #   raise 'Define in subclass'
    # end


   

    # def status(routine, index, commit_after: nil, denominator: nil)
    #   # print '.' # one dot per client processed
    #   # $stdout.flush
    #   @progress.format = "#{@progress_format} clients_#{routine.downcase}:#{index}/#{denominator} =="
    #   if commit_after && (index % commit_after == 0) && index != 0
    #     benchmark " sending db commit for last #{commit_after} clients" do
    #       GrdaWarehouseBase.connection.execute('COMMIT TRANSACTION; BEGIN TRANSACTION')
    #     end
    #   end
    # end

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
