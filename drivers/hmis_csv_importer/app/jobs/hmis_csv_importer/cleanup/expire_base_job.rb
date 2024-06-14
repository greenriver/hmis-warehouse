module HmisCsvImporter::Cleanup
  class ExpireBaseJob < ApplicationJob
    # @param data_source_id [Integer, nil] the ID of the data source
    # @param retain_log_count [Integer] the number of retained log records
    # @param retain_after_date [DateTime] the date after which records are retained
    def perform(data_source_id: nil, retain_log_count: 10, retain_after_date: DateTime.current)
      @data_source_id = data_source_id
      @retain_log_count = retain_log_count * files_per_log
      @retain_after_date = retain_after_date

      models.each do |model|
        benchmark model.table_name.to_s do
          process_model(model)
        end
      end
    end

    protected

    def log(str)
      Rails.logger.info(str)
    end

    def benchmark(name)
      rr = nil
      elapsed = Benchmark.realtime { rr = yield }
      log "#{name} completed: #{elapsed.round(2)}s"
      rr
    end

    def files_per_log
      ::GrdaWarehouse::HmisImportConfig.active.where(data_source_id: @data_source_id).maximum(:file_count) || 1
    end
  end
end
