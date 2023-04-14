###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ServiceHistory
  class Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    include ArelHelper
    include NotifierConfig
    include ::ServiceHistory::Builder

    # Debugging
    attr_accessor :batch, :to_patch

    def initialize(client_ids: nil, batch_size: 250, force_sequential_processing: false)
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
        Rails.logger.info "Generating Service History #{'[DRY RUN!]' if @dry_run}"
        @client_ids = if @client_ids.present? && @client_ids.any?
          @client_ids
        else
          destination_client_scope.distinct.pluck(:id)
        end
        batches = @client_ids.each_slice(@batch_size)
        started_at = DateTime.now
        GrdaWarehouse::GenerateServiceHistoryLog.create(started_at: started_at, batches: batches.size)
        queue_clients(@client_ids)
        wait_for_clients(client_ids: @clients) if @force_sequential_processing
      ensure
        Rails.cache.delete(GrdaWarehouse::Tasks::SanityCheckServiceHistory::CACHE_KEY)
      end
    end

    def log_and_send_message msg
      Rails.logger.info msg
      @notifier.ping msg
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
  end
end
