###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Base class for loader and importer expiration jobs
#   * marks expired records in model
#   * enqueues a new job to process the next model in models()
#
#   Subclasses should define these methods
#   def log_id_field
#   end
#
#   def log_model
#   end
#
#   def models
#   end
#
module HmisCsvImporter::Cleanup
  class ExpireBaseJob < BaseJob
    include ReportingConcern
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # low priority
    def self.default_priority
      10
    end

    # @param model_name[String] the model to process
    # @param retain_item_count [Integer] the number of retained imported records to retain beyond the retention date
    # @param retain_after_date [DateTime] the date after which records are retained
    # @param batch_size [Integer] processing batch size
    def perform(model_name: nil, retain_item_count: 5, retain_after_date: DateTime.current - 2.weeks, batch_size: 50_000)
      @retain_item_count = retain_item_count
      @retain_after_date = retain_after_date
      @batch_size = batch_size

      # If we don't have any imports, we don't need to do cleanup
      return unless min_age_protected_id.present?
      return unless sufficient_imports?

      model, next_model = find_model_by_name(model_name)
      raise "invalid model #{model_name}" unless model

      with_lock(model) do
        benchmark(model.table_name.to_s) do
          process_model(model)
        end
      end

      if next_model
        # enqueue the job for the next model in series
        self.class.set(wait: 1.minute).perform_later(
          model_name: next_model.name,
          retain_item_count: retain_item_count,
          retain_after_date: retain_after_date,
          batch_size: batch_size
        )
      end
    end

    protected

    # returns tuple of [model, next_model]
    def find_model_by_name(model_name)
      list = models
      # if no model_name was provided, start at the beginning
      model_name ||= list.first.name

      list.each_with_index do |model, idx|
        if model.name == model_name
          next_model = list[idx + 1]
          return [model, next_model]
        end
      end
      nil
    end

    def with_lock(model)
      lock_name = "#{self.class.name.demodulize}:#{model.table_name}"
      log_model.with_advisory_lock(lock_name, timeout_seconds: 0) do
        yield
      end
    end

    def process_model(model)
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Start Processing: #{model.table_name}, rows overall: #{model.count}"
      batches(model).each do |batch|
        model.connection.execute(mark_expired_query(model, batch))
      end
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Completed Processing: #{model.table_name}, rows expired: #{model.where(expired: true).count}"
    end

    private def mark_expired_query(model, batch)
      key_field = model.hud_key
      <<~SQL
        UPDATE #{model.quoted_table_name} set expired = true where id in (
          select id from (
            select id, row_number() OVER (
              PARTITION BY "#{key_field}", data_source_id ORDER BY id DESC
            ) as row_num
            from #{model.quoted_table_name}
            where #{log_id_field} < #{min_age_protected_id}
            AND id BETWEEN #{batch[:min]} AND #{batch[:max]}
          ) subquery
           where subquery.row_num > #{@retain_item_count} -- ignore latest N beyond age protected
        )
      SQL
    end

    private def batches(model)
      sql = <<~SQL
        WITH numbered_rows AS (
          SELECT id, row_number() OVER (ORDER BY id) AS row_num
          FROM #{model.quoted_table_name}
        ),
        batches AS (
          SELECT
            id,
            row_num,
            ((row_num - 1) / #{@batch_size} + 1) AS batch_number
          FROM numbered_rows
        )
        SELECT
          MIN(id) AS batch_start,
          MAX(id) AS batch_end,
          batch_number
        FROM batches
        GROUP BY batch_number
        ORDER BY batch_number;
      SQL
      GrdaWarehouseBase.connection.select_rows(sql).map do |start_id, end_id, _|
        {
          min: start_id,
          max: end_id,
        }
      end
    end

    private def min_age_protected_id
      @min_age_protected_id ||= log_model.
        where(created_at: @retain_after_date...).
        minimum(:id).presence || log_model.maximum(:id)
    end

    private def sufficient_imports?
      log_model.count > @retain_item_count
    end
  end
end
