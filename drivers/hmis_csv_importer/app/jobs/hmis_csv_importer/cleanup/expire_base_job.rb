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
module HmisCsvImporter::Cleanup
  class ExpireBaseJob < ApplicationJob
    include ReportingConcern

    # @param data_source_id [Integer] the ID of the data source
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

    def process_model(model)
      candidates = model.
        with_deleted.
        where(data_source_id: @data_source_id).
        select(:id, model.hud_key, log_id_field, :expired)

      cnt = 0
      log "#{model.table_name} total: #{candidates.size}"
      candidates.in_batches(of: 5_000) do |batch|
        sequence_protected_id_map = query_sequence_protected_ids(model, batch)
        expired_ids = []
        valid_ids = []
        batch.each do |record|
          next if record.expired # don't update records we've already expired

          if record.send(log_id_field).in?(age_protected_ids)
            valid_ids << record.id
            next
          end

          sequence_protected_ids = sequence_protected_id_map[record[model.hud_key]]
          if sequence_protected_ids.present? && record.send(log_id_field).in?(sequence_protected_ids)
            valid_ids << record.id
            next
          end
          expired_ids << record.id
        end.map(&:id)

        model.where(id: valid_ids).update_all(expired: false) if valid_ids.any?
        model.where(id: expired_ids).update_all(expired: true) if expired_ids.any?
        # GC every 10 batches
        cnt += 1
        GC.start if cnt % 10 == 9
      end
      log "#{model.table_name} expired: #{candidates.where(expired: true).size}"
    end

    def query_sequence_protected_ids(model, batch)
      key_field = model.hud_key
      sql = <<~SQL
        SELECT subquery."#{key_field}", #{log_id_field} FROM (
          SELECT #{log_id_field}, "#{key_field}", row_number() OVER (PARTITION BY "#{key_field}" ORDER BY id DESC) AS row_num
          FROM "#{model.table_name}"
          WHERE id IN (#{batch.map(&:id).join(',')})
        ) subquery
        WHERE subquery.row_num <= #{@retain_log_count}
      SQL

      results = model.connection.select_rows(sql)
      results.each_with_object({}) do |ary, h|
        key, id = ary
        h[key] ||= []
        h[key].push(id)
      end
    end

    def age_protected_ids
      @age_protected_ids ||= log_model.
        where(data_source_id: @data_source_id).
        where(created_at: @retain_after_date...).
        pluck(:id).to_set
    end

    def files_per_log
      ::GrdaWarehouse::HmisImportConfig.active.where(data_source_id: @data_source_id).maximum(:file_count) || 1
    end
  end
end
