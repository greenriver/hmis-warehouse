###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Base class for loader and importer expiration jobs
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

    BATCH_SIZE = 50_000

    # @param data_source_id [Integer] the ID of the data source
    # @param retain_item_count [Integer] the number of retained imported records to retain beyond the retention date
    # @param retain_after_date [DateTime] the date after which records are retained
    def perform(data_source_id:, retain_item_count: 5, retain_after_date: DateTime.current - 2.weeks)
      @data_source_id = data_source_id
      @retain_item_count = retain_item_count
      @retain_after_date = retain_after_date

      # If we don't have any imports, we don't need to do cleanup
      return unless min_age_protected_id.present?
      return unless sufficient_imports?

      models.each do |model|
        benchmark model.table_name.to_s do
          process_model(model)
        end
      end
    end

    protected

    def process_model(model)
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Expiring: #{model.table_name} in data source #{@data_source_id}, rows overall: #{model.where(data_source_id: @data_source_id).count}"
      # NOTE: this step is very slow, do we need it?
      model.with_deleted.where(data_source_id: @data_source_id).update_all(expired: false)
      batches(model).each do |batch|
        model.connection.execute(mark_expired_query(model, batch))
      end
      # TODO: this can be removed (or at least the count query could be removed once we're comfortable with the results)
      log "Expired: #{model.table_name} in data source #{@data_source_id}, rows expired: #{model.where(data_source_id: @data_source_id, expired: true).count}"
    end

    private def mark_expired_query(model, batch)
      key_field = model.hud_key
      <<~SQL
        UPDATE "#{model.table_name}" set expired = true where id in (
          select id from (
            select id, row_number() OVER (
              PARTITION BY "#{key_field}", data_source_id ORDER BY id DESC
            ) as row_num
            from "#{model.table_name}"
            where #{log_id_field} < #{min_age_protected_id}
            and data_source_id = #{@data_source_id}
            and id >= #{batch[:min]}
            and id <= #{batch[:max]}
          ) subquery
           where subquery.row_num > #{@retain_item_count} -- ignore latest N beyond age protected
        )
      SQL
    end

    private def batches(model)
      sql = <<~SQL
        WITH numbered_rows AS (
          SELECT id, row_number() OVER (ORDER BY id) AS row_num
          FROM "#{model.table_name}"
          where data_source_id = #{@data_source_id}
        ),
        batches AS (
          SELECT
            id,
            row_num,
            ((row_num - 1) / #{BATCH_SIZE} + 1) AS batch_number
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
      log_model.where(data_source_id: @data_source_id).count > @retain_item_count
    end
  end
end
