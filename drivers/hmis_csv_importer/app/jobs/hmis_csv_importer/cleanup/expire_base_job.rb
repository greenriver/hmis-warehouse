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
    include ElapsedTimeHelper
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # low priority
    def self.default_priority
      10
    end

    # @param model_name[String] the model to process
    # @param retain_item_count [Integer] the number of retained imported records to retain beyond the retention date
    # @param retain_after_date [DateTime] the date after which records are retained
    def perform(model_name: nil, retain_item_count: 5, retain_after_date: DateTime.current - 2.weeks)
      @retain_item_count = retain_item_count
      @retain_after_date = retain_after_date

      model, next_model = find_model_by_name(model_name)
      raise "invalid model #{model_name}" unless model

      with_lock(model) do
        benchmark(model.table_name.to_s) do
          process_model(model) if sufficient_imports?
        end
      end

      return unless next_model

      # enqueue the job for the next model in series
      self.class.perform_later(
        model_name: next_model.name,
        retain_item_count: retain_item_count,
        retain_after_date: retain_after_date,
      )
    end

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
      start_time = Time.current
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Start Processing: #{model.table_name}, rows overall: #{model.with_deleted.count}"
      model.connection.execute(mark_expired_query(model))
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Completed Processing: #{model.table_name}, rows expired: #{model.with_deleted.where(expired: true).count} in #{elapsed_time(Time.current - start_time)}"
    end

    private def mark_expired_query(model)
      key_field = model.hud_key
      <<~SQL
        UPDATE #{model.quoted_table_name} SET expired = true WHERE id IN (
          SELECT id FROM (
            SELECT id, row_number() OVER (
              PARTITION BY "#{key_field}", data_source_id ORDER BY id DESC
            ) AS row_num
            FROM #{model.quoted_table_name}
          ) subquery
          WHERE subquery.row_num > #{@retain_item_count}
        )
        AND #{log_id_field} < #{min_age_protected_id}
      SQL
    end

    # if there no matching imports in the date range, return MAX_IDX SO we don't have conditionally fiddle with the SQL if it's nil
    MAX_IDX = 2**63
    private def min_age_protected_id
      @min_age_protected_id ||= log_model.
        where(created_at: @retain_after_date...).
        minimum(:id).presence || MAX_IDX
    end

    private def sufficient_imports?
      log_model.count > @retain_item_count
    end
  end
end
