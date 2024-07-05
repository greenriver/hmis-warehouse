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
    def perform(model_name: nil, retain_item_count: 5, retain_after_date: DateTime.current - 2.weeks)
      @retain_item_count = retain_item_count
      @retain_after_date = retain_after_date

      models_to_run = models
      if model_name
        models_to_run.filter! { |m| m.name == model_name }
        raise "invalid model #{model_name}" if models_to_run.empty?
      end

      models_to_run.each do |model|
        with_lock(model) do
          benchmark(model.table_name.to_s) do
            process_model(model) if sufficient_imports?
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
      overall_count = model.with_deleted.count
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Start Processing: #{model.table_name}, rows overall: #{overall_count}"

      with_tmp_table(model) do |table_name|
        populate_tmp_table(model, table_name)
        write_expirations(model, table_name)
      end

      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      expired_count = model.with_deleted.where(expired: true).count
      log "Completed Processing: #{model.table_name}, rows expired: #{expired_count} rows not_expired: #{overall_count - expired_count} in #{elapsed_time(Time.current - start_time)}"
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

    private def write_expirations(model, tmp_table_name)
      max_id = max_id_from_tmp_table(model, tmp_table_name) || 0
      batch_size = 50_000
      start_id = 0
      end_id = [batch_size, max_id].min
      while start_id < max_id
        model.connection.execute(expiration_update_query(model, tmp_table_name, start_id, end_id))
        start_id = end_id + 1
        end_id += batch_size
      end
    end

    private def max_id_from_tmp_table(model, tmp_table_name)
      model.connection.execute("SELECT max(id) from #{tmp_table_name}").first['max']
    end

    private def expiration_update_query(model, tmp_table_name, start_id, end_id)
      <<~SQL
        UPDATE #{model.quoted_table_name} source_table
        SET expired = true
        FROM #{tmp_table_name} tmp_table
        WHERE tmp_table.source_id = source_table.id
        AND tmp_table.id BETWEEN #{start_id} AND #{end_id}
      SQL
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
        ) as subquery
        WHERE row_num > #{@retain_item_count}
        AND #{log_id_field} < #{min_age_protected_id}
        AND (expired = false OR expired is NULL)
      SQL
    end

    # This inner query can't have any where clause so that the partition and row_number calculation work correctly
    private def partitioned_query(model)
      key_field = model.hud_key
      <<~SQL
        SELECT id, #{log_id_field}, expired,
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
