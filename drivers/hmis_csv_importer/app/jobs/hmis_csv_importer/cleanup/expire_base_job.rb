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

    # @param model_name[String] only run against one model, defaults to all models
    # @param retain_item_count [Integer] the number of retained imported records to retain beyond the retention date
    # @param retain_after_date [DateTime] the date after which records are retained
    # @param max_per_run [Integer] stop processing if we delete more records than this
    # @param dry_run [Boolean] do not run delete statements
    def perform(model_name: nil, retain_item_count: 5, retain_after_date: DateTime.current - 2.weeks, max_per_run: 30_000_000, batch_size: 500_000, dry_run: true)
      @retain_item_count = retain_item_count
      @retain_after_date = retain_after_date
      @dry_run = dry_run
      @batch_size = batch_size
      @rows_deleted = 0
      @max_per_run = max_per_run

      models_to_run = models
      if model_name
        models_to_run.filter! { |m| m.name == model_name }
        raise "invalid model #{model_name}" if models_to_run.empty?
      end

      catch(:max_rows_exceeded) do
        models_to_run.each do |model|
          with_lock(model) do
            benchmark(model.table_name.to_s) do
              throw(:max_rows_exceeded) if max_rows_exceeded?

              process_model(model) if sufficient_imports?
            end
          end
        end
      end
    end

    def with_lock(model)
      lock_name = "#{self.class.name.demodulize}:#{model.table_name}"
      log_model.with_advisory_lock(lock_name, timeout_seconds: 0) do
        yield
      end
    end

    def process_model(model)
      start_time = Time.current
      expired_count = 0
      overall_count = model.with_deleted.count
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Start Processing: #{model.table_name}, rows overall: #{overall_count}"

      with_tmp_table(model) do |table_name|
        populate_tmp_table(model, table_name)
        # write_expirations(model, table_name)
        expired_count = model.connection.execute("SELECT count(*) from #{table_name}").first['count']
        sweep(model, table_name) unless @dry_run
        log "Completed Processing: #{model.table_name}, rows expired: #{expired_count} rows not_expired: #{overall_count - expired_count} in #{elapsed_time(Time.current - start_time)}"
      end
    end

    private def with_tmp_table(model)
      model.connection.create_table tmp_table_name(model), temporary: true do |t|
        t.references :source, null: false, index: false
      end
      yield(tmp_table_name(model))
    ensure
      # drop tmp table explicitly since we will continue processing additional tables with this session
      model.connection.drop_table tmp_table_name(model)
    end

    private def tmp_table_name(model)
      "#{model.table_name.downcase}_tmp_exp"
    end

    private def sweep(model, tmp_table_name)
      max = max_id_from_tmp_table(model, tmp_table_name) || 0
      min = 0
      while min < max
        break if max_rows_exceeded?

        model.connection.execute(sweep_query(model, tmp_table_name, min, min + @batch_size))
        deleted_this_time = [max, @batch_size].min
        @rows_deleted += deleted_this_time
        min += @batch_size
      end
    end

    # To prevent too many IO operations, limit total number of deletes per run
    def max_rows_exceeded?
      @rows_deleted >= @max_per_run
    end

    private def sweep_query(model, tmp_table_name, min, max)
      <<~SQL
        WITH rows AS (select source_id from #{tmp_table_name} WHERE id BETWEEN #{min} AND #{max})
        DELETE FROM #{model.quoted_table_name}
        WHERE EXISTS (SELECT * FROM rows WHERE rows.source_id = #{model.quoted_table_name}.id)
      SQL
    end

    private def max_id_from_tmp_table(model, tmp_table_name)
      model.connection.execute("SELECT max(id) from #{tmp_table_name}").first['max']
    end

    private def populate_tmp_table(model, tmp_table_name)
      model.connection.execute(populate_tmp_table_query(model, tmp_table_name))
    end

    private def populate_tmp_table_query(model, tmp_table_name)
      <<~SQL
        INSERT INTO #{tmp_table_name} (source_id)
        #{relevant_id_query(model)}
      SQL
    end

    # Need to re-select the same columns so the where on "subquery" can correctly limit the rows
    private def relevant_id_query(model)
      <<~SQL
        SELECT id FROM (
          #{partitioned_query(model)}
        ) AS subquery
        WHERE row_num > #{@retain_item_count}
        AND #{log_id_field} < #{min_age_protected_id}
        LIMIT #{@max_per_run}
      SQL
    end

    # This inner query can't have any where clause so that the partition and row_number calculation work correctly
    private def partitioned_query(model)
      key_field = model.hud_key
      <<~SQL
        SELECT id, #{log_id_field},
          rank() OVER (PARTITION BY "#{key_field}", data_source_id ORDER BY id DESC) as row_num
        FROM #{model.quoted_table_name}
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
