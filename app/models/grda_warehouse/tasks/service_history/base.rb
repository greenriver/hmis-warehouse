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

    def initialize(client_ids: nil, batch_size: 250, force_sequential_processing: false)
      self.logger = Rails.logger
      setup_notifier('Service History Generator')
      @batch_size = batch_size
      @client_ids = Array(client_ids).uniq
      @force_sequential_processing = force_sequential_processing
    end

    def run!
      raise NotImplementedError
    end

    def process
      begin
        logger.info "Generating Service History #{'[DRY RUN!]' if @dry_run}"
        @client_ids = if @client_ids.present? && @client_ids.any?
          @client_ids
        else
          destination_client_scope.distinct.pluck(:id)
        end
        batches = @client_ids.each_slice(@batch_size)
        started_at = DateTime.now
        log = GrdaWarehouse::GenerateServiceHistoryLog.create(started_at: started_at, batches: batches.size)
        batches.each do |batch|
          if @force_sequential_processing
            ::ServiceHistory::RebuildEnrollmentsJob.new(client_ids: batch, log_id: log.id).perform_now
          else
            job = Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsJob.new(client_ids: batch, log_id: log.id), queue: :low_priority)

          end
        end
        unless @force_sequential_processing
          # Check for completion using a reasonable interval
          interval = if @client_ids.count < 25
            5
          else
            30
          end
          # self.class.wait_for_processing(interval: interval)
        end
      ensure
        Rails.cache.delete('sanity_check_count')
      end
    end

    def self.wait_for_processing interval: 30
      # you must manually process these in the test environment since there are no workers
      unless Rails.env.test?
        started = Time.now
        while Delayed::Job.where(queue: :low_priority, failed_at: nil).count > 0 do
          break if ((Time.now - started) / 1.hours) > 12
          sleep(interval)
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

    def ensure_there_are_no_extra_enrollments_in_service_history client_id
      client = GrdaWarehouse::Hud::Client.destination.find(client_id)
      return unless client.present?
      sh_enrollments = service_history_enrollment_source.entry.where(client_id: client_id).
        order(enrollment_group_id: :asc, project_id: :asc, data_source_id: :asc).
        distinct.
        pluck(:enrollment_group_id, :project_id, :data_source_id)
      source_enrollments = client.source_enrollments.
        order(EnrollmentID: :asc, ProjectID: :asc, data_source_id: :asc).
        distinct.
        pluck(:EnrollmentID, :ProjectID, :data_source_id)
      extra_enrollments = sh_enrollments - source_enrollments
      extra_enrollments.each do |enrollment_group_id, project_id, data_source_id|
        service_history_enrollment_source.where(
          client_id: client_id,
          enrollment_group_id: enrollment_group_id,
          project_id: project_id,
          data_source_id: data_source_id,
        ).delete_all
      end
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def destination_client_scope
      client_source.destination
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def warehouse_clients_processed_source
      GrdaWarehouse::WarehouseClientsProcessed
    end
  end
end
